import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/bmi.dart';

void main() {
  // At 100 cm the BMI equals the weight, so the thresholds can be checked exactly.
  Bmi at100cm(double weightKg) => Bmi.fromMeasurements(weightKg: weightKg, heightCm: 100);

  test('thang châu Á: dưới 18,5 / 18,5 đến dưới 23 / 23 đến dưới 25 / từ 25', () {
    const expected = [
      (18.4, BmiCategory.underweight),
      (18.5, BmiCategory.normal),
      (22.9, BmiCategory.normal),
      (23.0, BmiCategory.overweight),
      (24.9, BmiCategory.overweight),
      (25.0, BmiCategory.obese),
      (40.0, BmiCategory.obese),
    ];

    for (final (weight, category) in expected) {
      expect(at100cm(weight).category, category, reason: 'BMI $weight');
    }
  });

  test('số hiển thị bị cắt xuống 0,1 nên giữ đúng ngưỡng spec và luôn khớp nhãn', () {
    expect(at100cm(22.96).displayValue, 22.9);
    expect(at100cm(22.96).category, BmiCategory.normal);
    expect(at100cm(22.999).category, BmiCategory.normal);
    expect(at100cm(18.46).displayValue, 18.4);
    expect(at100cm(18.46).category, BmiCategory.underweight);
    expect(at100cm(24.99).category, BmiCategory.overweight);
  });

  test('64 kg, cao 160 cm: BMI đúng 25,0 (máy tính ra 24,999...) vẫn hiện 25,0 và là béo phì', () {
    final bmi = Bmi.fromMeasurements(weightKg: 64, heightCm: 160);

    expect(bmi.displayValue, 25.0);
    expect(bmi.category, BmiCategory.obese);
  });

  test('70 kg, cao 175 cm: BMI 22,857 hiện 22,8, bình thường', () {
    final bmi = Bmi.fromMeasurements(weightKg: 70, heightCm: 175);

    expect(bmi.displayValue, 22.8);
    expect(bmi.category, BmiCategory.normal);
  });

  test('58,5 kg, cao 165 cm: BMI 21,488 hiện 21,4', () {
    expect(Bmi.fromMeasurements(weightKg: 58.5, heightCm: 165).displayValue, 21.4);
  });
}
