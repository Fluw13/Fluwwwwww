import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/nutrient_targets.dart';

void main() {
  NutrientTargets targets({
    double kcal = 2000,
    double proteinMinGrams = 112,
    Set<HealthCondition> conditions = const {},
    bool limitsSugar = false,
  }) {
    return calculateNutrientTargets(
      kcal: kcal,
      proteinMinGrams: proteinMinGrams,
      conditions: conditions,
      limitsSugar: limitsSugar,
    );
  }

  test('2000 kcal, protein 112 g: béo 55,6 g, béo bão hòa < 22,2 g, đường < 50 g, tinh bột 263 g', () {
    final result = targets();

    expect(result.fatGrams, closeTo(500 / 9, 1e-9));
    expect(result.saturatedFatMaxGrams, closeTo(200 / 9, 1e-9));
    expect(result.sugarsMaxGrams, closeTo(50, 1e-9));
    expect(result.carbohydratesGrams, closeTo(263, 1e-9));
  });

  test('mỡ máu cao thì béo bão hòa dưới 7% năng lượng', () {
    expect(targets(conditions: {HealthCondition.dyslipidemia}).saturatedFatMaxGrams, closeTo(140 / 9, 1e-9));
  });

  test('tiểu đường hoặc bật giảm ngọt thì đường dưới 5% năng lượng', () {
    expect(targets(conditions: {HealthCondition.diabetes}).sugarsMaxGrams, closeTo(25, 1e-9));
    expect(targets(limitsSugar: true).sugarsMaxGrams, closeTo(25, 1e-9));
  });

  test('bệnh không có quy tắc (huyết áp, dạ dày, gout) không đổi chỉ tiêu', () {
    final result = targets(
      conditions: {HealthCondition.hypertension, HealthCondition.stomachUlcer, HealthCondition.gout},
    );

    expect(result.saturatedFatMaxGrams, closeTo(200 / 9, 1e-9));
    expect(result.sugarsMaxGrams, closeTo(50, 1e-9));
  });

  test('protein và béo dùng hết năng lượng thì tinh bột là 0, không phải trống', () {
    expect(targets(proteinMinGrams: 375).carbohydratesGrams, closeTo(0, 1e-9));
  });

  test('hồ sơ cực đoan làm tinh bột âm thì để trống, không ép về 0', () {
    expect(targets(kcal: 2864, proteinMinGrams: 540).carbohydratesGrams, isNull);
  });

  test('natri tối đa 2000 mg mỗi ngày theo WHO', () {
    expect(dailySodiumMaxMg, 2000);
  });
}
