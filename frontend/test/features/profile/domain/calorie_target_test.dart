import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

void main() {
  CalorieTarget target({required WeightGoal goal, double tdee = 1959.2, double weeklyChangeKg = 0.5}) {
    return calculateCalorieTarget(bmr: 1264, tdee: tdee, goal: goal, weeklyChangeKg: weeklyChangeKg);
  }

  test('giữ cân thì mục tiêu bằng TDEE', () {
    final result = target(goal: WeightGoal.maintain);

    expect(result.kcal, closeTo(1959.2, 1e-9));
    expect(result.isRaisedToBmr, isFalse);
  });

  test('tăng 0,5 kg/tuần thì cộng 550 kcal/ngày', () {
    expect(target(goal: WeightGoal.gain).kcal, closeTo(2509.2, 1e-9));
  });

  test('giảm 0,5 kg/tuần thì trừ 550 kcal/ngày', () {
    final result = target(goal: WeightGoal.lose);

    expect(result.kcal, closeTo(1409.2, 1e-9));
    expect(result.isRaisedToBmr, isFalse);
  });

  test('giảm 0,25 kg/tuần thì trừ 275 kcal/ngày', () {
    expect(target(goal: WeightGoal.lose, weeklyChangeKg: 0.25).kcal, closeTo(1684.2, 1e-9));
  });

  test('giảm cân không bao giờ thấp hơn BMR và báo là đã nâng lên BMR', () {
    final result = target(goal: WeightGoal.lose, tdee: 1516.8);

    expect(result.kcal, 1264);
    expect(result.isRaisedToBmr, isTrue);
  });

  test('vừa chạm BMR thì không tính là bị nâng', () {
    final result = target(goal: WeightGoal.lose, tdee: 1814);

    expect(result.kcal, 1264);
    expect(result.isRaisedToBmr, isFalse);
  });

  test('tốc độ phải lớn hơn 0 và không quá 0,5 kg/tuần', () {
    expect(() => target(goal: WeightGoal.lose, weeklyChangeKg: 0), throwsA(isA<ArgumentError>()));
    expect(() => target(goal: WeightGoal.gain, weeklyChangeKg: 0.51), throwsA(isA<ArgumentError>()));
    expect(target(goal: WeightGoal.gain, weeklyChangeKg: 0.5).kcal, closeTo(2509.2, 1e-9));
  });
}
