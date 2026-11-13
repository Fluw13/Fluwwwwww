import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/profile_tables.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/data/profile_storage_keys.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

ProfilesCompanion profileToRow(HealthProfile profile) {
  return ProfilesCompanion.insert(
    id: const Value(singleProfileId),
    displayName: Value(profile.displayName),
    sex: sexKeys[profile.sex]!,
    bmrFormula: Value(switch (profile.bmrFormulaForOther) {
      final formula? => bmrFormulaKeys[formula],
      null => null,
    }),
    birthDate: profile.birthDate.toString(),
    heightCm: profile.heightCm,
    weightKg: profile.weightKg,
    targetWeightKg: profile.targetWeightKg,
    activityLevel: activityLevelKeys[profile.activityLevel]!,
    trainingType: trainingTypeKeys[profile.trainingType]!,
    weeklyChangeKg: Value(profile.weeklyChangeKg),
    conditionNote: Value(profile.conditionNote),
    limitsSugar: profile.limitsSugar,
    dietStyle: Value(dietStyleKeys[profile.dietary.dietStyle]),
    allergyNote: Value(profile.dietary.allergyNote),
    plannedGoal: Value(weightGoalKeys[profile.plannedGoal]),
  );
}

List<String> conditionsToKeys(Set<HealthCondition> conditions) => [
  for (final condition in conditions) healthConditionKeys[condition]!,
];

/// Returns `null` when a required field holds a value this version cannot read, instead of crashing; a `null`
/// [dietary] means its rows could not be read either.
/// Unknown condition keys are skipped because conditions are optional.
HealthProfile? profileFromRow(ProfileRow row, Iterable<String> conditionKeys, DietaryPreferences? dietary) {
  final sex = valueForKey(sexKeys, row.sex);
  final birthDate = CalendarDate.tryParse(row.birthDate);
  final activityLevel = valueForKey(activityLevelKeys, row.activityLevel);
  final trainingType = valueForKey(trainingTypeKeys, row.trainingType);
  if (sex == null || birthDate == null || activityLevel == null || trainingType == null || dietary == null) {
    return null;
  }

  return HealthProfile(
    displayName: row.displayName,
    sex: sex,
    // An unknown formula key reads as "not chosen"; validation then asks adults to choose again.
    bmrFormulaForOther: switch (row.bmrFormula) {
      final key? => valueForKey(bmrFormulaKeys, key),
      null => null,
    },
    birthDate: birthDate,
    heightCm: row.heightCm,
    weightKg: row.weightKg,
    targetWeightKg: row.targetWeightKg,
    // Rows from before schema v3, or with an unknown key, take the direction the weights imply.
    plannedGoal:
        switch (row.plannedGoal) {
          final key? => valueForKey(weightGoalKeys, key),
          null => null,
        } ??
        WeightGoal.fromWeights(currentKg: row.weightKg, targetKg: row.targetWeightKg),
    activityLevel: activityLevel,
    trainingType: trainingType,
    weeklyChangeKg: row.weeklyChangeKg,
    conditions: {for (final key in conditionKeys) ?valueForKey(healthConditionKeys, key)},
    conditionNote: row.conditionNote,
    limitsSugar: row.limitsSugar,
    dietary: dietary,
  );
}
