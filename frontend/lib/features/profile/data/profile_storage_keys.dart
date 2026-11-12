import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';

/// Stored keys are fixed strings, not `name` or `index`, so renaming or reordering an enum never breaks saved profiles.
/// Never change an existing key; add new ones instead.
const Map<Sex, String> sexKeys = {Sex.male: 'male', Sex.female: 'female'};

const Map<ActivityLevel, String> activityLevelKeys = {
  ActivityLevel.sedentary: 'sedentary',
  ActivityLevel.light: 'light',
  ActivityLevel.moderate: 'moderate',
  ActivityLevel.active: 'active',
  ActivityLevel.veryActive: 'very_active',
};

const Map<TrainingType, String> trainingTypeKeys = {
  TrainingType.none: 'none',
  TrainingType.endurance: 'endurance',
  TrainingType.strength: 'strength',
};

const Map<HealthCondition, String> healthConditionKeys = {
  HealthCondition.diabetes: 'diabetes',
  HealthCondition.hypertension: 'hypertension',
  HealthCondition.dyslipidemia: 'dyslipidemia',
  HealthCondition.stomach: 'stomach',
  HealthCondition.lowBloodPressure: 'low_blood_pressure',
  HealthCondition.gout: 'gout',
};

/// Returns `null` for a key this app version does not know, e.g. one written by a newer version.
T? valueForKey<T>(Map<T, String> keys, String key) {
  for (final MapEntry(key: value, value: storedKey) in keys.entries) {
    if (storedKey == key) {
      return value;
    }
  }
  return null;
}
