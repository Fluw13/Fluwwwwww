import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/source_status.dart';

final class SearchResponse {
  SearchResponse({required this.query, required List<FoodItem> items, required Map<FoodSource, SourceStatus> sources})
    : items = List.unmodifiable(items),
      sources = Map.unmodifiable(sources);

  final String query;
  final List<FoodItem> items;
  final Map<FoodSource, SourceStatus> sources;

  /// True when a source failed, so some results may be missing.
  bool get isPartial => sources.values.contains(SourceStatus.unavailable);
}
