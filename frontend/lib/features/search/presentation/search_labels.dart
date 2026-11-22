import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
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

/// Every per-100 number carries this, so 26 kcal per 100 g is never read as the whole 440 ml bottle.
String per100Label(QuantityUnit unit) => 'Trong 100 ${unit.symbol}';

/// Next to the portion field when the source gives no serving or pack size. Grams and millilitres are never converted
/// silently; for a drink measured per 100 g the user is told the approximation they are making.
String packSizeMissingHint(QuantityUnit unit) => switch (unit) {
  QuantityUnit.milliliter => 'Nguồn không ghi dung tích. Nhập số ml trên bao bì (ví dụ cả chai 440 ml).',
  QuantityUnit.gram =>
    'Nguồn không ghi khối lượng hay dung tích. Nhập số g trên bao bì (đồ uống: 1 ml gần bằng 1 g, ví dụ cả chai '
        '440 ml ≈ 440 g).',
};

/// When the pack prints a serving that is not in the unit of the numbers ("1 portion (330 ml)" for numbers per 100 g).
String servingNotInUnitHint(QuantityUnit unit) => switch (unit) {
  QuantityUnit.milliliter => 'Khẩu phần trên bao bì không ghi theo ml. Nhập số ml bạn uống.',
  QuantityUnit.gram => 'Khẩu phần trên bao bì không ghi theo g. Nhập số g bạn ăn (đồ uống: 1 ml gần bằng 1 g).',
};

/// The chip for the whole pack: a bottle for drinks, a pack otherwise.
String packageChipLabel(double amount, QuantityUnit unit) => switch (unit) {
  QuantityUnit.milliliter => 'Cả chai (${formatDecimal(amount)} ml)',
  QuantityUnit.gram => 'Cả gói (${formatDecimal(amount)} g)',
};

const String suspectNutrientsNote = 'Số liệu nguồn có thể sai — hãy đối chiếu nhãn trên bao bì.';

const String productGoneNote = 'Sản phẩm không còn trên Open Food Facts, số liệu có thể đã cũ.';

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
