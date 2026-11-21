import 'package:fluw/core/nutrition/fluw_thresholds.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';

enum VerdictStatus {
  /// Calories within [calorieToleranceShare] of the target.
  onTarget,

  /// Protein at or above the lower end of its range.
  reached,

  /// Sugar (a suggestion), saturated fat or sodium not above it.
  withinLimit,
  below,

  /// Calories below [underLoggedShare] of the target: more likely a day logged in part than eaten that little, so no
  /// gap is told.
  maybeUnderLogged,
  over,

  /// Some foods lack this number and the known part cannot settle the verdict: within a limit or below a target could
  /// still change once the missing numbers are counted.
  incomplete,

  /// Every food of the day lacks this number.
  noData,
}

final class NutrientVerdict {
  const NutrientVerdict({
    required this.nutrient,
    required this.status,
    required this.eaten,
    required this.target,
    required this.missingCount,
  });

  final Nutrient nutrient;
  final VerdictStatus status;
  final double? eaten;
  final double target;

  /// Foods without this number; the verdict may be off when it is not 0.
  final int missingCount;

  bool get isGood =>
      status == VerdictStatus.onTarget || status == VerdictStatus.reached || status == VerdictStatus.withinLimit;

  /// How far from the target or over the limit, in the nutrient's unit and from the shown numbers; 0 when [isGood]
  /// or without data.
  double get gap => switch (status) {
    VerdictStatus.below => shownDifference(nutrient, amount: target, target: eaten!),
    VerdictStatus.over => shownDifference(nutrient, amount: eaten!, target: target),
    _ => 0,
  };
}

/// The end-of-day review: one verdict per target the profile has. Sodium is judged for every adult with targets,
/// saturated fat only with high blood lipids, like the diary's daily summary.
final class DayEvaluation {
  DayEvaluation(List<NutrientVerdict> verdicts) : verdicts = List.unmodifiable(verdicts);

  final List<NutrientVerdict> verdicts;

  bool get isBalanced => verdicts.isNotEmpty && verdicts.every((verdict) => verdict.isGood);

  bool get hasMissingData => verdicts.any((verdict) => verdict.missingCount > 0);
}

/// Empty when nothing was logged, so an empty day is never judged as "far below target".
DayEvaluation evaluateDay({required NutrientTotals totals, required int entryCount, required PersonalLimits limits}) {
  if (entryCount == 0) {
    return DayEvaluation(const []);
  }
  NutrientVerdict verdict(Nutrient nutrient, double target, VerdictStatus Function(double eaten) judge) {
    final total = totals[nutrient];
    final eaten = total.knownSum;
    return NutrientVerdict(
      nutrient: nutrient,
      status: eaten == null ? VerdictStatus.noData : _settle(judge(eaten), missingCount: total.missingCount),
      eaten: eaten,
      target: target,
      missingCount: total.missingCount,
    );
  }

  VerdictStatus limitJudge(Nutrient nutrient, double eaten, double max) =>
      isOverAsShown(nutrient, amount: eaten, target: max) ? VerdictStatus.over : VerdictStatus.withinLimit;

  final kcal = limits.dailyKcal;
  final proteinMin = limits.proteinMinG;
  final sugarsMax = limits.sugarsMaxG;
  final saturatedFatMax = limits.saturatedFatMaxG;
  final sodiumMax = limits.sodiumMaxMg;

  return DayEvaluation([
    if (kcal != null)
      verdict(Nutrient.energyKcal, kcal, (eaten) {
        bool isBelow(double share) => isBelowAsShown(Nutrient.energyKcal, amount: eaten, target: kcal * share);
        if (isBelow(underLoggedShare)) return VerdictStatus.maybeUnderLogged;
        if (isBelow(1 - calorieToleranceShare)) return VerdictStatus.below;
        if (isOverAsShown(Nutrient.energyKcal, amount: eaten, target: kcal * (1 + calorieToleranceShare))) {
          return VerdictStatus.over;
        }
        return VerdictStatus.onTarget;
      }),
    if (proteinMin != null)
      verdict(
        Nutrient.proteinG,
        proteinMin,
        (eaten) => isBelowAsShown(Nutrient.proteinG, amount: eaten, target: proteinMin)
            ? VerdictStatus.below
            : VerdictStatus.reached,
      ),
    if (sugarsMax != null)
      verdict(Nutrient.sugarsG, sugarsMax, (eaten) => limitJudge(Nutrient.sugarsG, eaten, sugarsMax)),
    if (limits.watchesSaturatedFat && saturatedFatMax != null)
      verdict(
        Nutrient.saturatedFatG,
        saturatedFatMax,
        (eaten) => limitJudge(Nutrient.saturatedFatG, eaten, saturatedFatMax),
      ),
    if (sodiumMax != null)
      verdict(Nutrient.sodiumMg, sodiumMax, (eaten) => limitJudge(Nutrient.sodiumMg, eaten, sodiumMax)),
  ]);
}

/// The known total is the least that was eaten: "over" and "reached" stand with gaps, anything else is not settled.
VerdictStatus _settle(VerdictStatus status, {required int missingCount}) =>
    missingCount == 0 || status == VerdictStatus.over || status == VerdictStatus.reached
    ? status
    : VerdictStatus.incomplete;
