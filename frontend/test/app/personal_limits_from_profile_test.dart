import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/personal_limits_from_profile.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';

import '../features/profile/domain/profile_fixture.dart';

void main() {
  final allergic = DietaryPreferences(
    allergies: {Allergen.milk: AllergySeverity.severe, Allergen.peanuts: AllergySeverity.mild},
    allergyNote: null,
    dietStyle: DietStyle.regular,
    preferences: const {},
  );

  test('người lớn: chỉ tiêu lấy từ hồ sơ, dị ứng thành tag Open Food Facts kèm tên tiếng Việt', () {
    final limits = personalLimitsFromProfile(
      buildProfile(dietary: allergic, conditions: {HealthCondition.diabetes, HealthCondition.hypertension}),
      today: fixtureToday,
    );

    expect(limits.severeAllergenTags, {'en:milk'});
    expect(limits.mildAllergenTags, {'en:peanuts'});
    expect(limits.allergenNames['en:milk'], 'Sữa');
    expect(limits.dailyKcal, closeTo(2083.0625, 1e-6));
    expect(limits.sugarsMaxG, closeTo(26.03828125, 1e-6));
    expect(limits.sodiumMaxMg, 2000);
    expect(limits.watchesSugar, isTrue);
    expect(limits.watchesSodium, isTrue);
    expect(limits.watchesSaturatedFat, isFalse);
  });

  test('dưới 18 tuổi: vẫn cảnh báo dị ứng nhưng không có chỉ tiêu calo, đường, natri', () {
    final limits = personalLimitsFromProfile(
      buildProfile(birthDate: CalendarDate(2010, 1, 1), weeklyChangeKg: null, dietary: allergic),
      today: fixtureToday,
    );

    expect(limits.severeAllergenTags, {'en:milk'});
    expect(limits.dailyKcal, isNull);
    expect(limits.sugarsMaxG, isNull);
    expect(limits.sodiumMaxMg, isNull);
  });

  test('giảm ngọt cũng làm đường được theo dõi', () {
    expect(personalLimitsFromProfile(buildProfile(limitsSugar: true), today: fixtureToday).watchesSugar, isTrue);
  });

  test('trường cho Trang Chủ: mục tiêu béo/tinh bột, tên, mục tiêu, loại chỉ tiêu và cờ chế độ ăn', () {
    final limits = personalLimitsFromProfile(
      buildProfile(
        displayName: 'An',
        dietary: DietaryPreferences(
          allergies: const {},
          allergyNote: null,
          dietStyle: DietStyle.vegan,
          preferences: const {FoodPreference.steamedOrBoiled, FoodPreference.likesNuts},
        ),
      ),
      today: fixtureToday,
    );

    expect(limits.fatTargetG, closeTo(2083.0625 * 0.25 / 9, 1e-6));
    expect(limits.carbohydratesTargetG, closeTo((2083.0625 - 126 * 4 - 2083.0625 * 0.25) / 4, 1e-6));
    expect(limits.displayName, 'An');
    expect(limits.goalLabel, 'Giảm cân');
    expect(limits.targetsKind, TargetsKind.adult);
    expect(limits.avoidsAnimalProducts, isTrue);
    expect(limits.limitsCarbohydrates, isFalse);
    expect(limits.prefersSteamedOrBoiled, isTrue);
    expect(limits.likesNuts, isTrue);
  });

  test('keto, dưới 18 tuổi, dưới 14 tuổi, hồ sơ chưa hợp lệ', () {
    PersonalLimits of(HealthProfile profile) => personalLimitsFromProfile(profile, today: fixtureToday);
    final keto = DietaryPreferences(
      allergies: const {},
      allergyNote: null,
      dietStyle: DietStyle.keto,
      preferences: const {},
    );

    expect(of(buildProfile(dietary: keto)).limitsCarbohydrates, isTrue);
    expect(of(buildProfile(birthDate: CalendarDate(2010, 1, 1), weeklyChangeKg: null)).targetsKind, TargetsKind.teen);
    expect(
      of(buildProfile(birthDate: CalendarDate(2015, 1, 1), weeklyChangeKg: null)).targetsKind,
      TargetsKind.belowMinimumAge,
    );
    expect(of(buildProfile(heightCm: 50)).targetsKind, TargetsKind.invalid);
  });
}
