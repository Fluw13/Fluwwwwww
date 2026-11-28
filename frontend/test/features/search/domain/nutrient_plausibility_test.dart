import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/features/search/domain/nutrient_plausibility.dart';

bool _suspect(Map<Nutrient, double> values) => areNutrientsSuspect(Nutrients(values));

void main() {
  test('protein + carb + béo quá 105 g trong 100 g thì nghi ngờ, kể cả khi thiếu năng lượng', () {
    expect(_suspect({Nutrient.proteinG: 50, Nutrient.carbohydratesG: 50, Nutrient.fatG: 5.1}), isTrue);
    expect(_suspect({Nutrient.proteinG: 50, Nutrient.carbohydratesG: 50, Nutrient.fatG: 5}), isFalse);
  });

  test('năng lượng lệch quá 30% và quá 40 kcal so với 4P + 4C + 9F thì nghi ngờ', () {
    const macros = {Nutrient.proteinG: 0.8, Nutrient.carbohydratesG: 4.0, Nutrient.fatG: 0.9};
    expect(_suspect({...macros, Nutrient.energyKcal: 26}), isFalse, reason: '27,3 kcal theo công thức');
    expect(_suspect({...macros, Nutrient.energyKcal: 114}), isTrue, reason: 'nhập số cả chai vào ô trong 100 ml');
    expect(
      _suspect({Nutrient.proteinG: 5, Nutrient.carbohydratesG: 0, Nutrient.fatG: 0, Nutrient.energyKcal: 0}),
      isFalse,
      reason: 'lệch 100% nhưng chỉ 20 kcal',
    );
    expect(
      _suspect({Nutrient.proteinG: 10, Nutrient.carbohydratesG: 30, Nutrient.fatG: 10, Nutrient.energyKcal: 175}),
      isFalse,
      reason: 'lệch 75 kcal nhưng chỉ 30% của 250',
    );
    expect(
      _suspect({Nutrient.proteinG: 10, Nutrient.carbohydratesG: 30, Nutrient.fatG: 10, Nutrient.energyKcal: 174}),
      isTrue,
    );
  });

  test('thiếu một trong bốn số thì không xét độ lệch năng lượng', () {
    expect(_suspect({Nutrient.proteinG: 1, Nutrient.carbohydratesG: 1, Nutrient.energyKcal: 500}), isFalse);
  });
}
