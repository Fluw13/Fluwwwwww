import 'package:fluw/core/nutrition/portion_limits.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_quantity.dart';

/// A number followed by a gram or millilitre unit that is not the start of a longer word ("50 gói" is not grams).
final RegExp _amountWithUnit = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(grams|gram|gam|gr|g|ml)(?!\p{L})',
  caseSensitive: false,
  unicode: true,
);

/// The amount, in [unit], of the serving printed on a pack: "1 bottle (355 ml)" → 355, "30g" → 30. The last amount
/// wins, since sources put the measure after the household unit. Rounded to 0.1 like the portion field. Null when
/// there is no amount in [unit] (g and ml are never converted) or it is not a valid portion.
double? servingAmount(String? servingSize, QuantityUnit unit) {
  if (servingSize == null) {
    return null;
  }
  final match = _amountWithUnit.allMatches(servingSize).lastOrNull;
  if (match == null) {
    return null;
  }
  final matchedUnit = match.group(2)!.toLowerCase() == 'ml' ? QuantityUnit.milliliter : QuantityUnit.gram;
  final amount = double.parse(match.group(1)!.replaceAll(',', '.'));
  return portionOf(FoodQuantity(amount: amount, unit: matchedUnit), unit);
}

/// [quantity] as a portion in [unit], rounded to 0.1 like the portion field; null in another unit (never converted)
/// or outside the portion limits.
double? portionOf(FoodQuantity? quantity, QuantityUnit unit) {
  if (quantity == null || quantity.unit != unit) {
    return null;
  }
  final rounded = (quantity.amount * 10).round() / 10;
  return isValidPortion(rounded) ? rounded : null;
}

/// One serving in the unit of the numbers: the server's number first, the printed text as a fallback.
double? servingPortion(FoodItem item) =>
    portionOf(item.servingQuantity, item.facts.unit) ?? servingAmount(item.servingSize, item.facts.unit);

/// The whole pack or bottle in the unit of the numbers.
double? packagePortion(FoodItem item) => portionOf(item.packageQuantity, item.facts.unit);

/// The portion the detail screen starts on: a serving, else the whole pack, else 100.
double defaultPortion(FoodItem item) => servingPortion(item) ?? packagePortion(item) ?? 100;

/// The serving text worth showing: one with a number ("1 bottle (355 ml)"), not a bare word like "serving".
String? printedServing(String? servingSize) =>
    servingSize != null && RegExp(r'\d').hasMatch(servingSize) ? servingSize : null;
