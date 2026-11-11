import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

void main() {
  WeightGoal goal(double current, double target) => WeightGoal.fromWeights(currentKg: current, targetKg: target);

  test('cân nặng mong muốn thấp hơn thì là giảm cân', () {
    expect(goal(70, 65), WeightGoal.lose);
  });

  test('cân nặng mong muốn cao hơn thì là tăng cân', () {
    expect(goal(70, 72), WeightGoal.gain);
    expect(goal(70, 70.1), WeightGoal.gain);
  });

  test('hai cân nặng làm tròn đến 0,1 kg mà bằng nhau thì là giữ cân', () {
    expect(goal(70, 70), WeightGoal.maintain);
    expect(goal(70, 70.04), WeightGoal.maintain);
    expect(goal(70, 69.96), WeightGoal.maintain);
    expect(goal(69.96, 70.04), WeightGoal.maintain);
  });
}
