import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/water_target.dart';

void main() {
  test('35 ml cho mỗi kg cân nặng', () {
    expect(calculateWaterTargetMl(weightKg: 70), 2450);
    expect(calculateWaterTargetMl(weightKg: 58.5), closeTo(2047.5, 1e-9));
  });
}
