import 'package:fluw/core/nutrition/nutrition_facts.dart';

/// A food a feature wants to put into the diary. The facts are copied, so a later change in the source data never
/// rewrites what the user ate.
final class LoggedFood {
  LoggedFood({
    required this.name,
    required this.sourceFoodId,
    required this.facts,
    required this.quantity,
    required this.eatenAt,
  }) {
    if (!quantity.isFinite || quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Phải lớn hơn 0');
    }
  }

  final String name;

  /// The backend id (`off:...`, `usda:...`) when the food came from a source; kept for reference only.
  final String? sourceFoodId;
  final NutritionFacts facts;

  /// In the unit of [facts].
  final double quantity;
  final DateTime eatenAt;
}
