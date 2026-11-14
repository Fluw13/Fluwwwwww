import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/features/search/domain/food_item.dart';

/// The design's quick criteria, applied per 100 g / 100 ml. A food without the needed number never matches,
/// so missing data is not mistaken for a low or high value.
enum QuickFilter {
  lowSugar(Nutrient.sugarsG, 5, isMaximum: true),
  highProtein(Nutrient.proteinG, 20, isMaximum: false),
  under200Kcal(Nutrient.energyKcal, 200, isMaximum: true);

  const QuickFilter(this.nutrient, this.threshold, {required this.isMaximum});

  final Nutrient nutrient;
  final double threshold;
  final bool isMaximum;

  bool matches(FoodItem item) {
    final value = item.facts.per100[nutrient];
    if (value == null) {
      return false;
    }
    return isMaximum ? value < threshold : value > threshold;
  }
}

List<FoodItem> applyQuickFilters(List<FoodItem> items, Set<QuickFilter> filters) =>
    List.unmodifiable(items.where((item) => filters.every((filter) => filter.matches(item))));
