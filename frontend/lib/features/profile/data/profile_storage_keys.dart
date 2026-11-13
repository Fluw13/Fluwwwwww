import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';

/// Stored keys are fixed strings, not `name` or `index`, so renaming or reordering an enum never breaks saved profiles.
/// Never change an existing key; add new ones instead.
const Map<Sex, String> sexKeys = {Sex.male: 'male', Sex.female: 'female', Sex.other: 'other'};

const Map<BmrFormula, String> bmrFormulaKeys = {BmrFormula.male: 'male', BmrFormula.female: 'female'};

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

const Map<Allergen, String> allergenKeys = {
  Allergen.gluten: 'gluten',
  Allergen.crustaceans: 'crustaceans',
  Allergen.eggs: 'eggs',
  Allergen.fish: 'fish',
  Allergen.peanuts: 'peanuts',
  Allergen.soybeans: 'soybeans',
  Allergen.milk: 'milk',
  Allergen.treeNuts: 'tree_nuts',
  Allergen.celery: 'celery',
  Allergen.mustard: 'mustard',
  Allergen.sesame: 'sesame',
  Allergen.sulphites: 'sulphites',
  Allergen.lupin: 'lupin',
  Allergen.molluscs: 'molluscs',
};

const Map<AllergySeverity, String> allergySeverityKeys = {
  AllergySeverity.severe: 'severe',
  AllergySeverity.mild: 'mild',
};

const Map<DietStyle, String> dietStyleKeys = {
  DietStyle.regular: 'regular',
  DietStyle.eatClean: 'eat_clean',
  DietStyle.keto: 'keto',
  DietStyle.vegan: 'vegan',
  DietStyle.mediterranean: 'mediterranean',
};

const Map<FoodPreference, String> foodPreferenceKeys = {
  FoodPreference.noOrganMeat: 'no_organ_meat',
  FoodPreference.steamedOrBoiled: 'steamed_or_boiled',
  FoodPreference.likesNuts: 'likes_nuts',
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
