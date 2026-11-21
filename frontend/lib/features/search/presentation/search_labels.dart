import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/quick_filter.dart';

String quickFilterLabel(QuickFilter filter) => switch (filter) {
  QuickFilter.lowSugar => 'Đường ≤ ${formatDecimal(lowSugarMaxPer100g)} g',
  QuickFilter.highProtein => 'Protein ≥ ${formatDecimal(highProteinMinPer100)} g',
  QuickFilter.under200Kcal => 'Dưới ${formatWhole(lowEnergyBelowKcalPer100)} kcal',
};

/// Shown while the sugar filter is on, so a drink hidden at 4 g per 100 ml is not a surprise.
final String lowSugarDrinkNote = 'Đồ uống: đường ≤ ${formatDecimal(lowSugarMaxPer100ml)} g trong 100 ml.';

String foodSourceLabel(FoodSource source) => switch (source) {
  FoodSource.openFoodFacts => 'Open Food Facts',
  FoodSource.usda => 'USDA',
};

String nutrientLabel(Nutrient nutrient) => switch (nutrient) {
  Nutrient.energyKcal => 'Năng lượng',
  Nutrient.proteinG => 'Protein (đạm)',
  Nutrient.carbohydratesG => 'Carb (bột đường)',
  Nutrient.sugarsG => 'Đường tổng',
  Nutrient.fatG => 'Chất béo',
  Nutrient.saturatedFatG => 'Béo bão hòa',
  Nutrient.sodiumMg => 'Natri',
};

String nutrientUnit(Nutrient nutrient) => switch (nutrient) {
  Nutrient.energyKcal => 'kcal',
  Nutrient.sodiumMg => 'mg',
  _ => 'g',
};

/// kcal and mg read as whole numbers, as on nutrition labels and everywhere else in the app; grams keep one decimal.
String formatNutrientAmount(Nutrient nutrient, double value) =>
    '${formatShownAmount(nutrient, value)} ${nutrientUnit(nutrient)}';
