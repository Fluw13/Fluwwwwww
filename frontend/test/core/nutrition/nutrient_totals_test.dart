import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/nutrients.dart';

void main() {
  test('cộng các giá trị đã biết và đếm số món thiếu dữ liệu', () {
    final totals = NutrientTotals.of([
      Nutrients({Nutrient.energyKcal: 200, Nutrient.proteinG: 10}),
      Nutrients({Nutrient.energyKcal: 150}),
      Nutrients({Nutrient.energyKcal: 50.5, Nutrient.proteinG: 2.5}),
    ]);

    expect(totals[Nutrient.energyKcal].knownSum, closeTo(400.5, 1e-9));
    expect(totals[Nutrient.energyKcal].isComplete, isTrue);
    expect(totals[Nutrient.proteinG].knownSum, closeTo(12.5, 1e-9));
    expect(totals[Nutrient.proteinG].missingCount, 1);
    expect(totals[Nutrient.proteinG].isComplete, isFalse);
  });

  test('món nào cũng thiếu một chỉ số thì tổng là null, không phải 0', () {
    final totals = NutrientTotals.of([
      Nutrients({Nutrient.energyKcal: 200}),
      Nutrients({Nutrient.energyKcal: 150}),
    ]);

    expect(totals[Nutrient.sodiumMg].knownSum, isNull);
    expect(totals[Nutrient.sodiumMg].missingCount, 2);
  });

  test('món có giá trị 0 là dữ liệu thật nên tổng là 0', () {
    final totals = NutrientTotals.of([
      Nutrients({Nutrient.sugarsG: 0}),
    ]);

    expect(totals[Nutrient.sugarsG].knownSum, 0);
    expect(totals[Nutrient.sugarsG].isComplete, isTrue);
  });

  test('không có món nào thì tổng bằng 0 và không thiếu dữ liệu', () {
    final totals = NutrientTotals.of(const []);

    for (final nutrient in Nutrient.values) {
      expect(totals[nutrient].knownSum, 0);
      expect(totals[nutrient].isComplete, isTrue);
    }
  });
}
