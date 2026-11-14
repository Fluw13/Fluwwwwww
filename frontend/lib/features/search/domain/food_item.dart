import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/features/search/domain/food_attribution.dart';
import 'package:fluw/features/search/domain/food_source.dart';

/// One food from the backend. Nutrients the source does not have are missing from [facts], never 0.
final class FoodItem {
  FoodItem({
    required this.id,
    required this.source,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.imageUrl,
    required this.servingSize,
    required this.facts,
    required List<String>? allergenTags,
    required this.attribution,
  }) : allergenTags = allergenTags == null ? null : List.unmodifiable(allergenTags);

  final String id;
  final FoodSource source;

  /// Null when the source has no name; the UI shows a placeholder.
  final String? name;
  final String? brand;
  final String? barcode;
  final Uri? imageUrl;
  final String? servingSize;
  final NutritionFacts facts;

  /// Null means unknown. An empty list only means none were recorded, never that the food is allergen-free.
  final List<String>? allergenTags;

  final FoodAttribution attribution;
}
