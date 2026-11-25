import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/food_item.dart';

/// "Low sugar" as food labels define it: drinks are held to half the amount of solid foods.
const double lowSugarMaxPer100g = 5;
const double lowSugarMaxPer100ml = 2.5;
const double highProteinMinPer100 = 20;
const double lowEnergyBelowKcalPer100 = 200;

/// The design's quick criteria, applied per 100 g / 100 ml. A food without the needed number never matches,
/// so missing data is not mistaken for a low or high value; neither does one whose numbers the server flags as
/// implausible.
enum QuickFilter {
  lowSugar,
  highProtein,
  under200Kcal;

  bool matches(FoodItem item) {
    if (item.nutrientsSuspect) {
      return false;
    }
    final per100 = item.facts.per100;
    final sugarMax = item.facts.unit == QuantityUnit.milliliter ? lowSugarMaxPer100ml : lowSugarMaxPer100g;
    return switch (this) {
      lowSugar => per100[Nutrient.sugarsG] != null && per100[Nutrient.sugarsG]! <= sugarMax,
      highProtein => per100[Nutrient.proteinG] != null && per100[Nutrient.proteinG]! >= highProteinMinPer100,
      under200Kcal => per100[Nutrient.energyKcal] != null && per100[Nutrient.energyKcal]! < lowEnergyBelowKcalPer100,
    };
  }
}

List<FoodItem> applyQuickFilters(List<FoodItem> items, Set<QuickFilter> filters) =>
    List.unmodifiable(items.where((item) => filters.every((filter) => filter.matches(item))));
