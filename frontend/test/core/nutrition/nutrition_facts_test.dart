import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';

void main() {
  test('330 ml nước ngọt từ số liệu cho 100 ml', () {
    final cola = NutritionFacts(
      per100: Nutrients({Nutrient.energyKcal: 42, Nutrient.sugarsG: 10.6}),
      unit: QuantityUnit.milliliter,
    );

    final can = cola.forQuantity(330);

    expect(can[Nutrient.energyKcal], closeTo(138.6, 1e-9));
    expect(can[Nutrient.sugarsG], closeTo(34.98, 1e-9));
  });

  test('cùng số liệu nhưng khác đơn vị thì không bằng nhau', () {
    final per100 = Nutrients({Nutrient.energyKcal: 42});

    expect(
      NutritionFacts(per100: per100, unit: QuantityUnit.gram),
      NutritionFacts(per100: Nutrients({Nutrient.energyKcal: 42}), unit: QuantityUnit.gram),
    );
    expect(
      NutritionFacts(per100: per100, unit: QuantityUnit.gram),
      isNot(NutritionFacts(per100: per100, unit: QuantityUnit.milliliter)),
    );
  });
}
