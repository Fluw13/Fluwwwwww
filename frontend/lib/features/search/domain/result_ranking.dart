import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/features/search/domain/food_item.dart';

/// The numbers a result card shows.
const List<Nutrient> cardNutrients = [Nutrient.energyKcal, Nutrient.proteinG, Nutrient.sugarsG];

/// False when the source has none of the card's numbers: such a result can not be judged or logged usefully.
bool hasCardNutrition(FoodItem item) => cardNutrients.any((nutrient) => item.facts.per100[nutrient] != null);

/// Results without numbers go last, the rest keep the sources' order.
List<FoodItem> withNutritionFirst(List<FoodItem> items) =>
    List.unmodifiable([...items.where(hasCardNutrition), ...items.where((item) => !hasCardNutrition(item))]);
