import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';

final class NutrientTotal {
  const NutrientTotal({required this.knownSum, required this.missingCount});

  /// Null when no item has data for this nutrient, so the UI shows "no data" instead of 0.
  final double? knownSum;
  final int missingCount;

  bool get isComplete => missingCount == 0;
}

final class NutrientTotals {
  NutrientTotals.of(Iterable<Nutrients> items) : _totals = _sum(items.toList());

  final Map<Nutrient, NutrientTotal> _totals;

  NutrientTotal operator [](Nutrient nutrient) => _totals[nutrient]!;

  static Map<Nutrient, NutrientTotal> _sum(List<Nutrients> items) {
    return {for (final nutrient in Nutrient.values) nutrient: _totalOf(items.map((item) => item[nutrient]).toList())};
  }

  static NutrientTotal _totalOf(List<double?> values) {
    final known = values.nonNulls.toList();
    final missingCount = values.length - known.length;
    return NutrientTotal(
      knownSum: known.isEmpty && missingCount > 0 ? null : known.fold<double>(0, (sum, value) => sum + value),
      missingCount: missingCount,
    );
  }
}
