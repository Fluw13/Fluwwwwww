import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

void main() {
  test('kcal và mg hiện số nguyên như nhãn dinh dưỡng; gram giữ 1 chữ số thập phân', () {
    expect(formatNutrientAmount(Nutrient.energyKcal, 42.25), '42 kcal');
    expect(formatNutrientAmount(Nutrient.energyKcal, 1850), '1,850 kcal');
    expect(formatNutrientAmount(Nutrient.sodiumMg, 74.4), '74 mg');
    expect(formatNutrientAmount(Nutrient.fatG, 3.57), '3.6 g');
    expect(formatNutrientAmount(Nutrient.proteinG, 31.02), '31 g');
  });
}
