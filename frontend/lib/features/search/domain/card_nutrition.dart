import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_source.dart';

/// The numbers a result card shows.
const List<Nutrient> cardNutrients = [Nutrient.energyKcal, Nutrient.proteinG, Nutrient.sugarsG];

/// False when the search result has none of the card's numbers.
bool hasCardNutrition(FoodItem item) => cardNutrients.any((nutrient) => item.facts.per100[nutrient] != null);

/// True when the detail screen looks the product up by barcode, which often has numbers the search result lacks:
/// Open Food Facts' search index lags behind its products, so such results keep their place in the list.
bool hasProductLookup(FoodItem item) => item.source == FoodSource.openFoodFacts && item.barcode != null;
