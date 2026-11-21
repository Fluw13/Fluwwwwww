import 'dart:math';

import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';

/// kcal and mg are shown as whole numbers and grams with one decimal, everywhere in the app.
String formatShownAmount(Nutrient nutrient, double amount) =>
    _isWhole(nutrient) ? formatWhole(amount) : formatDecimal(amount);

/// Whether [amount] is above [target] as both are shown on screen: "25.0 / 25.0 g" is never over and "25.1 / 25.0 g"
/// always is. The one rule for "over" on Trang Chủ, Nhật Ký, the day review and the food detail.
bool isOverAsShown(Nutrient nutrient, {required double amount, required double target}) =>
    _steps(nutrient, amount) > _steps(nutrient, target);

/// Whether [amount] is below [target] as both are shown, e.g. protein not yet at its minimum.
bool isBelowAsShown(Nutrient nutrient, {required double amount, required double target}) =>
    _steps(nutrient, amount) < _steps(nutrient, target);

/// [amount] − [target] worked out from the shown numbers, so an "over" never comes with a gap that reads 0.
double shownDifference(Nutrient nutrient, {required double amount, required double target}) =>
    (_steps(nutrient, amount) - _steps(nutrient, target)) / (_isWhole(nutrient) ? 1 : 10);

/// [amount] as a whole percentage of [target] (above 0) that agrees with [isOverAsShown]: above 100 only when over,
/// so "100%" never sits next to "over" and "101%" never next to "within".
int percentAsShown(Nutrient nutrient, {required double amount, required double target}) {
  final percent = (amount / target * 100).round();
  return isOverAsShown(nutrient, amount: amount, target: target) ? max(percent, 101) : min(percent, 100);
}

bool _isWhole(Nutrient nutrient) => nutrient == Nutrient.energyKcal || nutrient == Nutrient.sodiumMg;

// Read back from the same digits the formatters print, so a comparison can never disagree with the screen.
int _steps(Nutrient nutrient, double amount) =>
    _isWhole(nutrient) ? amount.round() : (double.parse(amount.toStringAsFixed(1)) * 10).round();
