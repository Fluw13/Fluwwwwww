import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/data/profile_storage_keys.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';

void main() {
  void expectComplete<T>(Map<T, String> keys, List<T> values) {
    expect(keys.keys, unorderedEquals(values), reason: 'mỗi giá trị enum phải có khóa lưu');
    expect(keys.values.toSet(), hasLength(keys.length), reason: 'khóa lưu không được trùng');
  }

  test('mọi giá trị enum đều có một khóa lưu riêng', () {
    expectComplete(sexKeys, Sex.values);
    expectComplete(bmrFormulaKeys, BmrFormula.values);
    expectComplete(allergenKeys, Allergen.values);
    expectComplete(allergySeverityKeys, AllergySeverity.values);
    expectComplete(dietStyleKeys, DietStyle.values);
    expectComplete(foodPreferenceKeys, FoodPreference.values);
    expectComplete(activityLevelKeys, ActivityLevel.values);
    expectComplete(trainingTypeKeys, TrainingType.values);
    expectComplete(healthConditionKeys, HealthCondition.values);
  });

  // Saved profiles depend on these exact strings; this test fails if someone edits a key instead of adding one.
  test('khóa đã lưu không bao giờ đổi', () {
    expect(sexKeys.values, ['male', 'female', 'other']);
    expect(bmrFormulaKeys.values, ['male', 'female']);
    expect(allergenKeys.values, [
      'gluten',
      'crustaceans',
      'eggs',
      'fish',
      'peanuts',
      'soybeans',
      'milk',
      'tree_nuts',
      'celery',
      'mustard',
      'sesame',
      'sulphites',
      'lupin',
      'molluscs',
    ]);
    expect(allergySeverityKeys.values, ['severe', 'mild']);
    expect(dietStyleKeys.values, ['regular', 'eat_clean', 'keto', 'vegan', 'mediterranean']);
    expect(foodPreferenceKeys.values, ['no_organ_meat', 'steamed_or_boiled', 'likes_nuts']);
    expect(activityLevelKeys.values, ['sedentary', 'light', 'moderate', 'active', 'very_active']);
    expect(trainingTypeKeys.values, ['none', 'endurance', 'strength']);
    expect(healthConditionKeys.values, [
      'diabetes',
      'hypertension',
      'dyslipidemia',
      'stomach',
      'low_blood_pressure',
      'gout',
    ]);
  });

  test('khóa lạ trả null', () {
    expect(valueForKey(healthConditionKeys, 'asthma'), isNull);
    expect(valueForKey(healthConditionKeys, 'gout'), HealthCondition.gout);
  });
}
