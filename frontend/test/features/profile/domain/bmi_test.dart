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

  test('xếp loại theo số đã làm tròn 0,1, đúng số hiện trên màn hình', () {
    expect(at100cm(22.94).roundedValue, 22.9);
    expect(at100cm(22.94).category, BmiCategory.normal);
    expect(at100cm(22.96).roundedValue, 23.0);
    expect(at100cm(22.96).category, BmiCategory.overweight);
    expect(at100cm(18.44).category, BmiCategory.underweight);
    expect(at100cm(18.46).category, BmiCategory.normal);
  });

  test('70 kg, cao 175 cm: BMI 22,9, bình thường', () {
    final bmi = Bmi.fromMeasurements(weightKg: 70, heightCm: 175);

    expect(bmi.roundedValue, 22.9);
    expect(bmi.category, BmiCategory.normal);
  });

  test('58,5 kg, cao 165 cm: BMI 21,5', () {
    expect(Bmi.fromMeasurements(weightKg: 58.5, heightCm: 165).roundedValue, 21.5);
  });
}
