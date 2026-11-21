import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';
import 'package:fluw/features/profile/domain/protein_target.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

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
    expect(adult.calories.isRaisedToMinimum, isFalse);
    expect(adult.referenceWeight.isCapped, isFalse);
    expect(adult.protein.group, ProteinGroup.cutting);
    expect(adult.protein.minGrams, closeTo(112, 1e-9));
    expect(adult.protein.maxGrams, closeTo(168, 1e-9));
    expect(adult.nutrients.fatGrams, closeTo(57.86284722, 1e-6));
    expect(adult.nutrients.saturatedFatMaxGrams, closeTo(23.14513889, 1e-6));
    expect(adult.nutrients.sugarsMaxGrams, closeTo(52.0765625, 1e-9));
    expect(adult.nutrients.carbohydratesGrams, closeTo(278.57421875, 1e-6));
    expect(adult.bmi.displayValue, 22.8);
    expect(adult.bmi.category, BmiCategory.normal);
    expect(adult.waterMl, 2450);
  });

  test('BMI trên 24,9 thì đạm và nước tính theo cân nặng tham chiếu, BMR vẫn theo cân nặng thật', () {
    final adult =
        calculateDailyTargets(buildProfile(weightKg: 100, targetWeightKg: 90), today: fixtureToday) as AdultTargets;

    expect(adult.bmr, 1998.75);
    expect(adult.referenceWeight.isCapped, isTrue);
    expect(adult.referenceWeight.kg, closeTo(76.25625, 1e-9));
    expect(adult.protein.minGrams, closeTo(122.01, 1e-9));
    expect(adult.protein.maxGrams, closeTo(183.015, 1e-9));
    expect(adult.waterMl, closeTo(2668.96875, 1e-9));
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
        targetWeightKg: 48,
        activityLevel: ActivityLevel.sedentary,
      ),
      today: fixtureToday,
    );

    final adult = targets as AdultTargets;
    expect(adult.bmr, 1239);
    expect(adult.calories.kcal, 1239);
    expect(adult.calories.raisedTo, CalorieFloor.bmr);
    expect(adult.nutrients.fatGrams, closeTo(34.41666667, 1e-6));
    expect(adult.nutrients.sugarsMaxGrams, closeTo(30.975, 1e-9));
    expect(adult.nutrients.carbohydratesGrams, closeTo(152.3125, 1e-9));
  });

  group('mức calo tối thiểu khi giảm cân', () {
    CalorieTarget caloriesOf(Sex sex, {BmrFormula? formula, double heightCm = 150}) {
      final profile = buildProfile(
        sex: sex,
        bmrFormulaForOther: formula,
        weightKg: 50,
        heightCm: heightCm,
        targetWeightKg: 48,
        activityLevel: ActivityLevel.sedentary,
      );
      return (calculateDailyTargets(profile, today: fixtureToday) as AdultTargets).calories;
    }

    test('nữ BMR 1.176,5 thì nâng lên 1.200 kcal', () {
      final calories = caloriesOf(Sex.female);

      expect(calories.kcal, 1200);
      expect(calories.raisedTo, CalorieFloor.womenMinimum);
    });

    test('nam BMR 1.405 thì nâng lên 1.500 kcal', () {
      final calories = caloriesOf(Sex.male, heightCm: 160);

      expect(calories.kcal, 1500);
      expect(calories.raisedTo, CalorieFloor.menMinimum);
    });

    test('giới tính Khác dùng mức tối thiểu theo công thức BMR đã chọn', () {
      expect(caloriesOf(Sex.other, formula: BmrFormula.female).raisedTo, CalorieFloor.womenMinimum);
      final asMale = caloriesOf(Sex.other, formula: BmrFormula.male);
      expect(asMale.kcal, 1500);
      expect(asMale.raisedTo, CalorieFloor.menMinimum);
    });
  });

  test('bật giảm ngọt trong hồ sơ thì giới hạn đường 5% năng lượng', () {
    final targets = calculateDailyTargets(buildProfile(limitsSugar: true), today: fixtureToday);

    expect((targets as AdultTargets).nutrients.sugarsMaxGrams, closeTo(26.03828125, 1e-9));
  });

  test('tròn 18 tuổi đúng hôm nay thì tính như người lớn', () {
    expect(targetsFor(CalendarDate(2008, 11, 11)), isA<AdultTargets>());
  });

  test('còn 1 ngày nữa mới 18 tuổi thì không tính gì', () {
    expect(targetsFor(CalendarDate(2008, 11, 12)), isA<BelowMinimumAge>());
  });

  test('hồ sơ cũ của người 16 tuổi (chưa có tốc độ đổi cân) vẫn đọc được, chỉ không có chỉ tiêu', () {
    final targets = calculateDailyTargets(
      buildProfile(birthDate: CalendarDate(2010, 1, 1), weeklyChangeKg: null),
      today: fixtureToday,
    );

    expect(targets, isA<BelowMinimumAge>());
  });

  group('mang thai hoặc cho con bú', () {
    test('trả lời Có thì không có số nào, kể cả khi muốn giảm cân mà chưa chọn tốc độ', () {
      final targets = calculateDailyTargets(
        buildProfile(sex: Sex.female, isPregnantOrBreastfeeding: true, weeklyChangeKg: null),
        today: fixtureToday,
      );

      expect(targets, isA<PregnancyOrBreastfeeding>());
    });

    test('giới tính Khác theo công thức Nữ cũng được hỏi', () {
      final targets = calculateDailyTargets(
        buildProfile(sex: Sex.other, bmrFormulaForOther: BmrFormula.female, isPregnantOrBreastfeeding: true),
        today: fixtureToday,
      );

      expect(targets, isA<PregnancyOrBreastfeeding>());
    });

    test('nữ chưa trả lời (hồ sơ lưu trước khi có câu hỏi) thì báo cần trả lời, không tính số', () {
      final targets = calculateDailyTargets(
        buildProfile(sex: Sex.female, isPregnantOrBreastfeeding: null),
        today: fixtureToday,
      );

      expect((targets as InvalidProfile).issues, {ProfileIssue.pregnancyAnswerMissing});
    });

    test('công thức Nam thì câu trả lời bị bỏ, vẫn tính như thường', () {
      final profile = buildProfile(sex: Sex.male, isPregnantOrBreastfeeding: true);

      expect(profile.isPregnantOrBreastfeeding, isNull);
      expect(calculateDailyTargets(profile, today: fixtureToday), isA<AdultTargets>());
    });

    test('dưới 18 tuổi thì báo theo tuổi trước', () {
      final targets = calculateDailyTargets(
        buildProfile(sex: Sex.female, isPregnantOrBreastfeeding: true, birthDate: CalendarDate(2010, 1, 1)),
        today: fixtureToday,
      );

      expect(targets, isA<BelowMinimumAge>());
    });
  });

  test('cân nặng mong muốn cho BMI dưới 18,5 thì không tính chỉ tiêu', () {
    final targets = calculateDailyTargets(buildProfile(targetWeightKg: 56.6), today: fixtureToday);

    expect((targets as InvalidProfile).issues, {ProfileIssue.targetBmiTooLow});
  });

  test('hồ sơ không hợp lệ thì trả về danh sách lỗi, không ném lỗi', () {
    final targets = calculateDailyTargets(buildProfile(heightCm: 40), today: fixtureToday);

    expect(targets, isA<InvalidProfile>());
    expect((targets as InvalidProfile).issues, {ProfileIssue.heightOutOfRange});
  });

  test('giới tính Khác dùng công thức BMR người dùng chọn', () {
    final asFemale = calculateDailyTargets(
      buildProfile(sex: Sex.other, bmrFormulaForOther: BmrFormula.female),
      today: fixtureToday,
    );
    final asMale = calculateDailyTargets(
      buildProfile(sex: Sex.other, bmrFormulaForOther: BmrFormula.male),
      today: fixtureToday,
    );

    expect((asFemale as AdultTargets).bmr, 1698.75 - 166);
    expect((asMale as AdultTargets).bmr, 1698.75);
  });

  test('người lớn giới tính Khác chưa chọn công thức BMR thì báo lỗi hồ sơ, không crash', () {
    final targets = calculateDailyTargets(buildProfile(sex: Sex.other), today: fixtureToday);

    expect((targets as InvalidProfile).issues, {ProfileIssue.bmrFormulaMissing});
  });

  test('đã đạt cân nặng mong muốn khi đang giảm cân thì calo bằng TDEE, không chuyển sang tăng cân', () {
    final reached = buildProfile(weightKg: 64.8, targetWeightKg: 65, plannedGoal: WeightGoal.lose);

    final adult = calculateDailyTargets(reached, today: fixtureToday) as AdultTargets;
    expect(adult.calories.kcal, closeTo(adult.tdee, 1e-9));
  });
}
