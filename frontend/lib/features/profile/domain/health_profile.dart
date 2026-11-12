import 'package:collection/collection.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

final class HealthProfile {
  HealthProfile({
    required this.displayName,
    required this.sex,
    required this.bmrFormulaForOther,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.trainingType,
    this.weeklyChangeKg,
    required Set<HealthCondition> conditions,
    required this.conditionNote,
    required this.limitsSugar,
  }) : conditions = Set.unmodifiable(conditions);

  /// Optional; only shown in the app.
  final String? displayName;

  final Sex sex;

  /// Only used when [sex] is [Sex.other]; see [bmrFormula].
  final BmrFormula? bmrFormulaForOther;

  final CalendarDate birthDate;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final ActivityLevel activityLevel;
  final TrainingType trainingType;

  /// Only needed for adults who want to lose or gain weight.
  final double? weeklyChangeKg;

  final Set<HealthCondition> conditions;

  /// Conditions the user typed in; kept as a note only, never used to change targets.
  final String? conditionNote;

  /// The "giảm ngọt" eating preference; lowers the sugar limit like diabetes does.
  final bool limitsSugar;

  /// `null` only for [Sex.other] without a chosen formula, which validation rejects for adults.
  BmrFormula? get bmrFormula => switch (sex) {
    Sex.male => BmrFormula.male,
    Sex.female => BmrFormula.female,
    Sex.other => bmrFormulaForOther,
  };

  WeightGoal get goal => WeightGoal.fromWeights(currentKg: weightKg, targetKg: targetWeightKg);

  /// Nullable fields take a function so `null` can be set on purpose: `copyWith(weeklyChangeKg: () => null)` clears it.
  HealthProfile copyWith({
    String? Function()? displayName,
    Sex? sex,
    BmrFormula? Function()? bmrFormulaForOther,
    CalendarDate? birthDate,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    TrainingType? trainingType,
    double? Function()? weeklyChangeKg,
    Set<HealthCondition>? conditions,
    String? Function()? conditionNote,
    bool? limitsSugar,
  }) {
    return HealthProfile(
      displayName: displayName == null ? this.displayName : displayName(),
      sex: sex ?? this.sex,
      bmrFormulaForOther: bmrFormulaForOther == null ? this.bmrFormulaForOther : bmrFormulaForOther(),
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      trainingType: trainingType ?? this.trainingType,
      weeklyChangeKg: weeklyChangeKg == null ? this.weeklyChangeKg : weeklyChangeKg(),
      conditions: conditions ?? this.conditions,
      conditionNote: conditionNote == null ? this.conditionNote : conditionNote(),
      limitsSugar: limitsSugar ?? this.limitsSugar,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HealthProfile &&
      other.displayName == displayName &&
      other.sex == sex &&
      other.bmrFormulaForOther == bmrFormulaForOther &&
      other.birthDate == birthDate &&
      other.heightCm == heightCm &&
      other.weightKg == weightKg &&
      other.targetWeightKg == targetWeightKg &&
      other.activityLevel == activityLevel &&
      other.trainingType == trainingType &&
      other.weeklyChangeKg == weeklyChangeKg &&
      const SetEquality<HealthCondition>().equals(other.conditions, conditions) &&
      other.conditionNote == conditionNote &&
      other.limitsSugar == limitsSugar;

  @override
  int get hashCode => Object.hash(
    displayName,
    sex,
    bmrFormulaForOther,
    birthDate,
    heightCm,
    weightKg,
    targetWeightKg,
    activityLevel,
    trainingType,
    weeklyChangeKg,
    Object.hashAllUnordered(conditions),
    conditionNote,
    limitsSugar,
  );
}
