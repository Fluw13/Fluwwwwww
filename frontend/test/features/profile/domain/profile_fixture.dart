import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';

final CalendarDate fixtureToday = CalendarDate(2026, 11, 11);

HealthProfile buildProfile({
  String? displayName,
  Sex sex = Sex.male,
  BmrFormula? bmrFormulaForOther,
  CalendarDate? birthDate,
  double heightCm = 175,
  double weightKg = 70,
  double targetWeightKg = 65,
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
    birthDate: birthDate ?? CalendarDate(2006, 5, 13),
    heightCm: heightCm,
    weightKg: weightKg,
    targetWeightKg: targetWeightKg,
    activityLevel: activityLevel,
    trainingType: trainingType,
    weeklyChangeKg: weeklyChangeKg,
    conditions: conditions,
    conditionNote: conditionNote,
    limitsSugar: limitsSugar,
    dietary: dietary ?? DietaryPreferences.none(),
  );
}
