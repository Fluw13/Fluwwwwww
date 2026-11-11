import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';

final class NutrientTotal {
  const NutrientTotal({required this.knownSum, required this.missingCount});

  final double knownSum;
  final int missingCount;

  bool get isComplete => missingCount == 0;
}

final class NutrientTotals {
  NutrientTotals.of(Iterable<Nutrients> items) : _totals = _sum(items.toList());

  final Map<Nutrient, NutrientTotal> _totals;

  NutrientTotal operator [](Nutrient nutrient) => _totals[nutrient]!;

  static Map<Nutrient, NutrientTotal> _sum(List<Nutrients> items) {
    return {
      for (final nutrient in Nutrient.values)
        nutrient: NutrientTotal(
          knownSum: items.fold(0, (sum, item) => sum + (item[nutrient] ?? 0)),
          missingCount: items.where((item) => item[nutrient] == null).length,
        ),
    };
  }
}
