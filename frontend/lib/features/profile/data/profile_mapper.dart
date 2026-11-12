import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/profile_tables.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/data/profile_storage_keys.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';

ProfilesCompanion profileToRow(HealthProfile profile) {
  return ProfilesCompanion.insert(
    id: const Value(singleProfileId),
    sex: sexKeys[profile.sex]!,
    birthDate: profile.birthDate.toString(),
    heightCm: profile.heightCm,
    weightKg: profile.weightKg,
    targetWeightKg: profile.targetWeightKg,
    activityLevel: activityLevelKeys[profile.activityLevel]!,
    trainingType: trainingTypeKeys[profile.trainingType]!,
    weeklyChangeKg: Value(profile.weeklyChangeKg),
    conditionNote: Value(profile.conditionNote),
    limitsSugar: profile.limitsSugar,
  );
}

List<String> conditionsToKeys(Set<HealthCondition> conditions) => [
  for (final condition in conditions) healthConditionKeys[condition]!,
];

/// Returns `null` when a required field holds a value this version cannot read, so the app asks for the profile again
/// instead of crashing. Unknown condition keys are skipped because conditions are optional.
HealthProfile? profileFromRow(ProfileRow row, Iterable<String> conditionKeys) {
  final sex = valueForKey(sexKeys, row.sex);
  final birthDate = CalendarDate.tryParse(row.birthDate);
  final activityLevel = valueForKey(activityLevelKeys, row.activityLevel);
  final trainingType = valueForKey(trainingTypeKeys, row.trainingType);
  if (sex == null || birthDate == null || activityLevel == null || trainingType == null) {
    return null;
  }

  return HealthProfile(
    sex: sex,
    birthDate: birthDate,
    heightCm: row.heightCm,
    weightKg: row.weightKg,
    targetWeightKg: row.targetWeightKg,
    activityLevel: activityLevel,
    trainingType: trainingType,
    weeklyChangeKg: row.weeklyChangeKg,
    conditions: {for (final key in conditionKeys) ?valueForKey(healthConditionKeys, key)},
    conditionNote: row.conditionNote,
    limitsSugar: row.limitsSugar,
  );
}
