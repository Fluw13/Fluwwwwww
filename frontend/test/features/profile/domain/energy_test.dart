import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/energy.dart';

void main() {
  group('BMR Mifflin–St Jeor', () {
    test('nam: 10W + 6.25H - 5A + 5', () {
      expect(calculateBmr(formula: BmrFormula.male, weightKg: 70, heightCm: 175, ageYears: 20), 1698.75);
    });

    test('nữ: 10W + 6.25H - 5A - 161', () {
      expect(calculateBmr(formula: BmrFormula.female, weightKg: 55, heightCm: 160, ageYears: 25), 1264);
    });

    test('18 tuổi được tính', () {
      expect(calculateBmr(formula: BmrFormula.male, weightKg: 60, heightCm: 170, ageYears: 18), 1577.5);
    });

    test('dưới 18 tuổi thì không tính', () {
      expect(
        () => calculateBmr(formula: BmrFormula.male, weightKg: 60, heightCm: 170, ageYears: 17),
        throwsArgumentError,
      );
    });
  });

  group('TDEE = BMR × hệ số vận động', () {
    const expected = {
      ActivityLevel.sedentary: 1516.8,
      ActivityLevel.light: 1738.0,
      ActivityLevel.moderate: 1959.2,
      ActivityLevel.active: 2180.4,
      ActivityLevel.veryActive: 2401.6,
    };

    for (final MapEntry(key: level, value: tdee) in expected.entries) {
      test('${level.name}: 1264 × ${level.factor} = $tdee', () {
        expect(calculateTdee(bmr: 1264, activityLevel: level), closeTo(tdee, 1e-9));
      });
    }
  });
}
