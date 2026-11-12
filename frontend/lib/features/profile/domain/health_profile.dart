import 'package:collection/collection.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

const Object _unchanged = Object();

final class HealthProfile {
  HealthProfile({
    required this.sex,
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

  final Sex sex;
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

  WeightGoal get goal => WeightGoal.fromWeights(currentKg: weightKg, targetKg: targetWeightKg);

  /// The nullable fields take `null` to clear them; leave them out to keep the current value.
  HealthProfile copyWith({
    Sex? sex,
    CalendarDate? birthDate,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    TrainingType? trainingType,
    Object? weeklyChangeKg = _unchanged,
    Set<HealthCondition>? conditions,
    Object? conditionNote = _unchanged,
    bool? limitsSugar,
  }) {
    return HealthProfile(
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      trainingType: trainingType ?? this.trainingType,
      weeklyChangeKg: identical(weeklyChangeKg, _unchanged) ? this.weeklyChangeKg : weeklyChangeKg as double?,
      conditions: conditions ?? this.conditions,
      conditionNote: identical(conditionNote, _unchanged) ? this.conditionNote : conditionNote as String?,
      limitsSugar: limitsSugar ?? this.limitsSugar,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HealthProfile &&
      other.sex == sex &&
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
    sex,
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
