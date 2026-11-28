import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/data/food_item_json.dart';
import 'package:fluw/features/search/domain/custom_product.dart';
import 'package:fluw/features/search/domain/custom_product_item.dart';
import 'package:fluw/features/search/domain/food_quantity.dart';
import 'package:fluw/features/search/domain/food_source.dart';

import '../../../fixtures/food_api_samples.dart';

CustomProduct _product({double kcal = 26}) => CustomProduct(
  id: 'abc',
  name: 'Trà sữa latte',
  brand: 'Hãng X',
  barcode: '8935001282266',
  facts: NutritionFacts(
    per100: Nutrients({
      Nutrient.energyKcal: kcal,
      Nutrient.proteinG: 0.8,
      Nutrient.carbohydratesG: 4,
      Nutrient.fatG: 0.9,
    }),
    unit: QuantityUnit.milliliter,
  ),
  packageAmount: 440,
  servingAmount: 220,
  labelPerServing: true,
);

void main() {
  test('thành món của Tra Cứu: nguồn "tự nhập", số liệu, dung tích, khẩu phần; dị ứng chưa biết', () {
    final item = foodItemFromCustomProduct(_product());

    expect(item.source, FoodSource.custom);
    expect(item.name, 'Trà sữa latte');
    expect(item.brand, 'Hãng X');
    expect(item.barcode, '8935001282266');
    expect(item.facts, _product().facts);
    expect(item.packageQuantity, const FoodQuantity(amount: 440, unit: QuantityUnit.milliliter));
    expect(item.servingQuantity, const FoodQuantity(amount: 220, unit: QuantityUnit.milliliter));
    expect(item.allergenTags, isNull, reason: 'form không hỏi dị ứng, nên không được coi là không có');
    expect(item.imageUrl, isNull);
    expect(item.attribution.url, isNull);
    expect(item.nutrientsSuspect, isFalse);
    expect(customProductIdOf(item), 'abc');
  });

  test('số liệu không khớp thì món mang cờ nghi ngờ như số liệu của nguồn', () {
    expect(foodItemFromCustomProduct(_product(kcal: 114)).nutrientsSuspect, isTrue);
  });

  test('món của nguồn khác không có id sản phẩm tự nhập', () {
    expect(customProductIdOf(foodItemFromJson(yoghurtSearchItem)!), isNull);
  });
}
