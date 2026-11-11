import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';

/// Nutrient values per 100 [unit] (100 g or 100 ml), as food labels and Open Food Facts give them.
final class NutritionFacts {
  const NutritionFacts({required this.per100, required this.unit});

  final Nutrients per100;
  final QuantityUnit unit;

  /// [quantity] is in [unit].
  Nutrients forQuantity(double quantity) => per100.scaled(quantity / 100);

  @override
  bool operator ==(Object other) => other is NutritionFacts && other.per100 == per100 && other.unit == unit;

  @override
  int get hashCode => Object.hash(per100, unit);
}
