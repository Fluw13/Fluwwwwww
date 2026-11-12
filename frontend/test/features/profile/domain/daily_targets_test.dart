import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';
import 'package:fluw/features/profile/domain/protein_target.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';

import 'profile_fixture.dart';

void main() {
  DailyTargets targetsFor(CalendarDate birthDate) =>
      calculateDailyTargets(buildProfile(birthDate: birthDate), today: fixtureToday);

  test('người lớn: đủ BMR, TDEE, mục tiêu calo và protein', () {
    final targets = calculateDailyTargets(buildProfile(), today: fixtureToday);

    expect(targets, isA<AdultTargets>());
    final adult = targets as AdultTargets;
    expect(adult.bmr, 1698.75);
    expect(adult.tdee, closeTo(2633.0625, 1e-9));
    expect(adult.calories.kcal, closeTo(2083.0625, 1e-9));
    expect(adult.calories.isRaisedToBmr, isFalse);
    expect(adult.protein.group, ProteinGroup.cutting);
    expect(adult.protein.minGrams, closeTo(126, 1e-9));
    expect(adult.protein.maxGrams, closeTo(168, 1e-9));
    expect(adult.nutrients.fatGrams, closeTo(57.86284722, 1e-6));
    expect(adult.nutrients.saturatedFatMaxGrams, closeTo(23.14513889, 1e-6));
    expect(adult.nutrients.sugarsMaxGrams, closeTo(52.0765625, 1e-9));
    expect(adult.nutrients.carbohydratesGrams, closeTo(264.57421875, 1e-6));
    expect(adult.bmi.displayValue, 22.8);
    expect(adult.bmi.category, BmiCategory.normal);
    expect(adult.waterMl, 2450);
  });

  test('người lớn có tiểu đường và mỡ máu thì giới hạn đường 5%, béo bão hòa 7%', () {
    final targets = calculateDailyTargets(
      buildProfile(conditions: {HealthCondition.diabetes, HealthCondition.dyslipidemia}),
      today: fixtureToday,
    );

    final adult = targets as AdultTargets;
    expect(adult.nutrients.sugarsMaxGrams, closeTo(26.03828125, 1e-9));
    expect(adult.nutrients.saturatedFatMaxGrams, closeTo(16.20159722, 1e-6));
  });

  test('calo bị nâng lên BMR thì chỉ tiêu dinh dưỡng tính theo số đã nâng', () {
    final targets = calculateDailyTargets(
      buildProfile(
        sex: Sex.female,
        weightKg: 50,
        heightCm: 160,
        targetWeightKg: 45,
        activityLevel: ActivityLevel.sedentary,
      ),
      today: fixtureToday,
    );

    final adult = targets as AdultTargets;
    expect(adult.bmr, 1239);
    expect(adult.calories.kcal, 1239);
    expect(adult.calories.isRaisedToBmr, isTrue);
    expect(adult.nutrients.fatGrams, closeTo(34.41666667, 1e-6));
    expect(adult.nutrients.sugarsMaxGrams, closeTo(30.975, 1e-9));
    expect(adult.nutrients.carbohydratesGrams, closeTo(142.3125, 1e-9));
  });

  test('bật giảm ngọt trong hồ sơ thì giới hạn đường 5% năng lượng', () {
    final targets = calculateDailyTargets(buildProfile(limitsSugar: true), today: fixtureToday);

    expect((targets as AdultTargets).nutrients.sugarsMaxGrams, closeTo(26.03828125, 1e-9));
  });

  test('tròn 18 tuổi đúng hôm nay thì tính như người lớn', () {
    expect(targetsFor(CalendarDate(2008, 11, 11)), isA<AdultTargets>());
  });

  test('còn 1 ngày nữa mới 18 tuổi thì vẫn là nhóm 14 đến dưới 18', () {
    expect(targetsFor(CalendarDate(2008, 11, 12)), isA<TeenTargets>());
  });

  test('14 đến dưới 18 tuổi: không tính calo, chỉ có protein 0,85 g/kg', () {
    final targets = calculateDailyTargets(
      buildProfile(birthDate: CalendarDate(2010, 1, 1), weightKg: 55, trainingType: TrainingType.strength),
      today: fixtureToday,
    );

    expect(targets, isA<TeenTargets>());
    final teen = targets as TeenTargets;
    expect(teen.protein.group, ProteinGroup.teen);
    expect(teen.protein.minGrams, closeTo(46.75, 1e-9));
    expect(teen.waterMl, 1925);
  });

  test('tròn 14 tuổi đúng hôm nay thì được tính protein', () {
    expect(targetsFor(CalendarDate(2012, 11, 11)), isA<TeenTargets>());
  });

  test('còn 1 ngày nữa mới 14 tuổi thì không tính gì', () {
    expect(targetsFor(CalendarDate(2012, 11, 12)), isA<BelowMinimumAge>());
  });

  test('hồ sơ không hợp lệ thì trả về danh sách lỗi, không ném lỗi', () {
    final targets = calculateDailyTargets(buildProfile(heightCm: 40), today: fixtureToday);

    expect(targets, isA<InvalidProfile>());
    expect((targets as InvalidProfile).issues, {ProfileIssue.heightOutOfRange});
  });
}
