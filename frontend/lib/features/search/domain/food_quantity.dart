import 'package:fluw/core/nutrition/quantity_unit.dart';

/// An amount the source states as a number: the whole pack ("440 ml") or one serving ("330 ml").
final class FoodQuantity {
  const FoodQuantity({required this.amount, required this.unit});

  final double amount;
  final QuantityUnit unit;

  @override
  bool operator ==(Object other) => other is FoodQuantity && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);
}
