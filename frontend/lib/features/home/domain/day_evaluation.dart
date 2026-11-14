import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';

/// Calories count as on target within ±10% of the daily target: a day is never exactly on the number, and the target
/// itself is an estimate. Agent's choice, recorded in CLAUDE.md; FLuw can change it.
const double calorieToleranceShare = 0.10;

enum VerdictStatus {
  /// Calories within the tolerance.
  onTarget,

  /// Protein at or above the lower end of its range.
  reached,

  /// Sugar, saturated fat or sodium not above the limit.
  withinLimit,
  below,
  over,

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

  /// How far from the target or over the limit, in the nutrient's unit; 0 when [isGood] or without data.
  double get gap => switch (status) {
    VerdictStatus.below => target - eaten!,
    VerdictStatus.over => eaten! - target,
    _ => 0,
  };
}

/// The end-of-day review: one verdict per target the profile has. Sodium and saturated fat are judged only for the
/// conditions that track them, like the diary's daily summary.
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
      status: eaten == null ? VerdictStatus.noData : judge(eaten),
      eaten: eaten,
      target: target,
      missingCount: total.missingCount,
    );
  }

  VerdictStatus limitJudge(double eaten, double max) =>
      _roundedPercent(eaten, max) > 100 ? VerdictStatus.over : VerdictStatus.withinLimit;

  final kcal = limits.dailyKcal;
  final proteinMin = limits.proteinMinG;
  final sugarsMax = limits.sugarsMaxG;
  final saturatedFatMax = limits.saturatedFatMaxG;
  final sodiumMax = limits.sodiumMaxMg;

  return DayEvaluation([
    if (kcal != null)
      verdict(Nutrient.energyKcal, kcal, (eaten) {
        final percent = _roundedPercent(eaten, kcal);
        if (percent < 100 - calorieToleranceShare * 100) return VerdictStatus.below;
        if (percent > 100 + calorieToleranceShare * 100) return VerdictStatus.over;
        return VerdictStatus.onTarget;
      }),
    if (proteinMin != null)
      // Compared in tenths of a gram, like the profile's protein target.
      verdict(
        Nutrient.proteinG,
        proteinMin,
        (eaten) => (eaten * 10).round() >= (proteinMin * 10).round() ? VerdictStatus.reached : VerdictStatus.below,
      ),
    if (sugarsMax != null) verdict(Nutrient.sugarsG, sugarsMax, (eaten) => limitJudge(eaten, sugarsMax)),
    if (limits.watchesSaturatedFat && saturatedFatMax != null)
      verdict(Nutrient.saturatedFatG, saturatedFatMax, (eaten) => limitJudge(eaten, saturatedFatMax)),
    if (limits.watchesSodium && sodiumMax != null)
      verdict(Nutrient.sodiumMg, sodiumMax, (eaten) => limitJudge(eaten, sodiumMax)),
  ]);
}

int _roundedPercent(double eaten, double target) => (eaten / target * 100).round();
