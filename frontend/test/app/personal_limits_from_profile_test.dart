import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/personal_limits_from_profile.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';

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
}
