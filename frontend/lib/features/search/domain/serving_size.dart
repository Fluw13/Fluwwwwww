import 'package:fluw/core/nutrition/portion_limits.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';

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
  final rounded = (amount * 10).round() / 10;
  return matchedUnit == unit && isValidPortion(rounded) ? rounded : null;
}
