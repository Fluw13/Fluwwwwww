import 'package:fluw/features/search/domain/custom_product.dart';
import 'package:fluw/features/search/domain/food_attribution.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_quantity.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/nutrient_plausibility.dart';

const String _idPrefix = 'custom:';

const FoodAttribution customProductAttribution = FoodAttribution(
  source: 'Bạn tự nhập từ nhãn',
  license: 'chỉ lưu trên máy này',
  imageLicense: null,
  url: null,
);

/// The product as a food the search list, the detail screen and the diary already know. Allergens are unknown: the
/// form does not ask for them, so the detail screen tells the user to read the label.
FoodItem foodItemFromCustomProduct(CustomProduct product) {
  FoodQuantity? quantity(double? amount) =>
      amount == null ? null : FoodQuantity(amount: amount, unit: product.facts.unit);
  return FoodItem(
    id: '$_idPrefix${product.id}',
    source: FoodSource.custom,
    name: product.name,
    brand: product.brand,
    barcode: product.barcode,
    imageUrl: null,
    servingSize: null,
    facts: product.facts,
    allergenTags: null,
    attribution: customProductAttribution,
    packageQuantity: quantity(product.packageAmount),
    servingQuantity: quantity(product.servingAmount),
    nutrientsSuspect: areNutrientsSuspect(product.facts.per100),
  );
}

/// The id of the stored product behind [item], or null when [item] did not come from one.
String? customProductIdOf(FoodItem item) =>
    item.source == FoodSource.custom && item.id.startsWith(_idPrefix) ? item.id.substring(_idPrefix.length) : null;
