import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

final CalendarDate fixtureToday = CalendarDate(2026, 11, 11);

HealthProfile buildProfile({
  String? displayName,
  Sex sex = Sex.male,
  BmrFormula? bmrFormulaForOther,
  CalendarDate? birthDate,
  double heightCm = 175,
  double weightKg = 70,
  double targetWeightKg = 65,
  WeightGoal? plannedGoal,
  ActivityLevel activityLevel = ActivityLevel.moderate,
  TrainingType trainingType = TrainingType.strength,
  double? weeklyChangeKg = 0.5,
  Set<HealthCondition> conditions = const {},
  String? conditionNote,
  bool limitsSugar = false,
  DietaryPreferences? dietary,
}) {
  return HealthProfile(
    displayName: displayName,
    sex: sex,
    bmrFormulaForOther: bmrFormulaForOther,
    birthDate: birthDate ?? CalendarDate(2006, 3, 8),
    heightCm: heightCm,
    weightKg: weightKg,
    targetWeightKg: targetWeightKg,
    // Tests also build profiles with NaN weights; those cannot imply a direction.
    plannedGoal:
        plannedGoal ??
        (weightKg.isFinite && targetWeightKg.isFinite
            ? WeightGoal.fromWeights(currentKg: weightKg, targetKg: targetWeightKg)
            : WeightGoal.maintain),
    activityLevel: activityLevel,
    trainingType: trainingType,
    weeklyChangeKg: weeklyChangeKg,
    conditions: conditions,
    conditionNote: conditionNote,
    limitsSugar: limitsSugar,
    dietary: dietary ?? DietaryPreferences.none(),
  );
}
