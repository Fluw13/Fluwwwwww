import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

void main() {
  CalorieTarget target({
    required WeightGoal goal,
    double bmr = 1264,
    double tdee = 1959.2,
    BmrFormula formula = BmrFormula.female,
    double? weeklyChangeKg = 0.5,
  }) {
    return calculateCalorieTarget(bmr: bmr, tdee: tdee, formula: formula, goal: goal, weeklyChangeKg: weeklyChangeKg);
  }

  test('giữ cân thì mục tiêu bằng TDEE và không cần tốc độ đổi cân', () {
    final result = target(goal: WeightGoal.maintain, weeklyChangeKg: null);

    expect(result.kcal, closeTo(1959.2, 1e-9));
    expect(result.isRaisedToMinimum, isFalse);
  });

  test('tăng 0,5 kg/tuần thì cộng 550 kcal/ngày', () {
    expect(target(goal: WeightGoal.gain).kcal, closeTo(2509.2, 1e-9));
  });

  test('giảm 0,5 kg/tuần thì trừ 550 kcal/ngày', () {
    final result = target(goal: WeightGoal.lose);

    expect(result.kcal, closeTo(1409.2, 1e-9));
    expect(result.raisedTo, isNull);
  });

  test('giảm 0,25 kg/tuần thì trừ 275 kcal/ngày', () {
    expect(target(goal: WeightGoal.lose, weeklyChangeKg: 0.25).kcal, closeTo(1684.2, 1e-9));
  });

  test('BMR cao hơn mức tối thiểu: giảm cân không thấp hơn BMR và báo đã nâng lên BMR', () {
    final result = target(goal: WeightGoal.lose, tdee: 1516.8);

    expect(result.kcal, 1264);
    expect(result.raisedTo, CalorieFloor.bmr);
    expect(result.isRaisedToMinimum, isTrue);
  });

  test('vừa chạm BMR thì không tính là bị nâng', () {
    final result = target(goal: WeightGoal.lose, tdee: 1814);

    expect(result.kcal, 1264);
    expect(result.isRaisedToMinimum, isFalse);
  });

  test('nữ có BMR dưới 1.200: giảm cân không thấp hơn 1.200 kcal', () {
    // 1320 − 550 = 770 kcal, dưới cả BMR 1100.
    final result = target(goal: WeightGoal.lose, bmr: 1100, tdee: 1320);

    expect(result.kcal, 1200);
    expect(result.raisedTo, CalorieFloor.womenMinimum);
  });

  test('nam có BMR dưới 1.500: giảm cân không thấp hơn 1.500 kcal', () {
    final result = target(goal: WeightGoal.lose, bmr: 1400, tdee: 1680, formula: BmrFormula.male);

    expect(result.kcal, 1500);
    expect(result.raisedTo, CalorieFloor.menMinimum);
  });

  test('nam có BMR trên 1.500 thì vẫn nâng lên BMR', () {
    final result = target(goal: WeightGoal.lose, bmr: 1600, tdee: 1920, formula: BmrFormula.male);

    expect(result.kcal, 1600);
    expect(result.raisedTo, CalorieFloor.bmr);
  });

  test('vừa chạm 1.200 kcal thì không tính là bị nâng', () {
    final result = target(goal: WeightGoal.lose, bmr: 1100, tdee: 1750);

    expect(result.kcal, 1200);
    expect(result.isRaisedToMinimum, isFalse);
  });

  test('mức tối thiểu cao hơn cả TDEE thì vẫn giữ mức tối thiểu', () {
    final result = target(goal: WeightGoal.lose, bmr: 900, tdee: 1080, weeklyChangeKg: 0.25);

    expect(result.kcal, 1200);
    expect(result.raisedTo, CalorieFloor.womenMinimum);
  });

  test('mức tối thiểu chỉ áp cho giảm cân: giữ cân với TDEE dưới 1.200 thì vẫn bằng TDEE', () {
    final result = target(goal: WeightGoal.maintain, bmr: 900, tdee: 1080, weeklyChangeKg: null);

    expect(result.kcal, 1080);
    expect(result.isRaisedToMinimum, isFalse);
  });

  test('mức tối thiểu: nữ 1.200 kcal, nam 1.500 kcal', () {
    expect(minimumIntakeKcal(BmrFormula.female), 1200);
    expect(minimumIntakeKcal(BmrFormula.male), 1500);
  });

  test('tốc độ thực tế theo mức chênh với TDEE: 550 kcal/ngày là 0,5 kg/tuần, 238 kcal/ngày khoảng 0,22 kg/tuần', () {
    expect(weeklyChangeKgFromDailyGap(550), closeTo(0.5, 1e-9));
    expect(weeklyChangeKgFromDailyGap(238), closeTo(0.2163636, 1e-6));
  });

  test('tăng hoặc giảm cân thì tốc độ phải có, lớn hơn 0 và không quá 0,5 kg/tuần', () {
    expect(() => target(goal: WeightGoal.lose, weeklyChangeKg: null), throwsArgumentError);
    expect(() => target(goal: WeightGoal.lose, weeklyChangeKg: 0), throwsArgumentError);
    expect(() => target(goal: WeightGoal.gain, weeklyChangeKg: 0.51), throwsArgumentError);
  });

  group('isValidWeeklyChangeKg', () {
    test('chấp nhận 0,5 kể cả khi phép cộng số thực ra 0,5000000000000001', () {
      expect(isValidWeeklyChangeKg(0.5), isTrue);
      expect(isValidWeeklyChangeKg(0.1 * 3 + 0.2), isTrue);
    });

    test('từ chối 0, số âm, vượt 0,5 và NaN', () {
      expect(isValidWeeklyChangeKg(0), isFalse);
      expect(isValidWeeklyChangeKg(-0.5), isFalse);
      expect(isValidWeeklyChangeKg(0.51), isFalse);
      expect(isValidWeeklyChangeKg(double.nan), isFalse);
    });
  });
}
