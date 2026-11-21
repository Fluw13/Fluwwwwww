import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/reference_weight.dart';

void main() {
  test('BMI đến 24,9 thì dùng cân nặng thật', () {
    final reference = ReferenceWeight.fromMeasurements(weightKg: 70, heightCm: 175);

    expect(reference.kg, 70);
    expect(reference.isCapped, isFalse);
  });

  test('BMI trên 24,9 thì dùng cân nặng ở BMI 24,9: 175 cm là 24,9 × 1,75² = 76,25625 kg', () {
    final reference = ReferenceWeight.fromMeasurements(weightKg: 100, heightCm: 175);

    expect(reference.kg, closeTo(76.25625, 1e-9));
    expect(reference.isCapped, isTrue);
  });

  test('đúng mốc BMI 24,9 thì chưa tính là bị giới hạn; nặng hơn một chút thì có', () {
    // 24.9 × 1.6² = 63.744 kg.
    expect(ReferenceWeight.fromMeasurements(weightKg: 63.744, heightCm: 160).isCapped, isFalse);
    final above = ReferenceWeight.fromMeasurements(weightKg: 63.8, heightCm: 160);
    expect(above.isCapped, isTrue);
    expect(above.kg, closeTo(63.744, 1e-9));
  });
}
