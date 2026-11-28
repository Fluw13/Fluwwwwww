import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:fluw/features/search/domain/custom_product_item.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/search_response.dart';
import 'package:fluw/features/search/domain/source_status.dart';
import 'package:fluw/features/search/domain/vietnamese_food_glossary.dart';
import 'package:fluw/features/search/presentation/search_state.dart';

const int minSearchLength = 2;

/// Same limit as the backend, so a long query never costs a request that can only fail.
const int maxSearchLength = 100;

/// Trims and collapses inner spaces, so "sữa   chua" and "sữa chua" are one search and one recent entry.
String normalizeQuery(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

final searchControllerProvider = NotifierProvider<SearchController, SearchState>(SearchController.new);

final class SearchController extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchIdle();

  /// Only the newest search may update the state; an older answer that arrives late is dropped.
  int _latestRequest = 0;

  /// [englishQuery] comes with a food recognized in a photo, for USDA; when it is missing or not a valid query, the
  /// glossary gives one for a typed fresh food ("cà chua" → "tomato"), since USDA names are English only.
  Future<void> search(String rawQuery, {String? englishQuery}) async {
    bool isValid(String query) => query.length >= minSearchLength && query.length <= maxSearchLength;
    final query = normalizeQuery(rawQuery);
    if (!isValid(query)) {
      return;
    }
    final english = englishQuery == null ? null : normalizeQuery(englishQuery);
    final usdaQuery = (english != null && isValid(english) ? english : null) ?? englishSearchTermFor(query);
    final request = ++_latestRequest;
    state = SearchLoading(query);
    // Never fails, so it can run while the sources are asked without an unhandled error.
    final storedSearch = _storedProducts(query);
    try {
      final response = await ref.read(foodApiProvider).search(query, englishQuery: usdaQuery);
      final stored = await storedSearch;
      if (request == _latestRequest) {
        final items = [...stored, ...response.items];
        state = SearchLoaded(
          SearchResponse(query: response.query, items: items, sources: response.sources),
          englishQuery: usdaQuery,
        );
      }
    } on ApiFailure catch (failure) {
      final stored = await storedSearch;
      if (request == _latestRequest) {
        // Offline the user's own products still answer; the list says a source is missing.
        state = stored.isEmpty
            ? SearchFailed(query, failure, englishQuery: usdaQuery)
            : SearchLoaded(
                SearchResponse(
                  query: query,
                  items: stored,
                  sources: const {
                    FoodSource.openFoodFacts: SourceStatus.unavailable,
                    FoodSource.usda: SourceStatus.unavailable,
                  },
                ),
                englishQuery: usdaQuery,
              );
      }
    }
  }

  /// The user's own products come first: they typed them from the label. A database error only loses them, so the
  /// sources still answer.
  Future<List<FoodItem>> _storedProducts(String query) async {
    try {
      final products = await ref.read(customProductRepositoryProvider).search(query);
      return [for (final product in products) foodItemFromCustomProduct(product)];
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'custom products'));
      return const [];
    }
  }

  /// Back to the empty screen (recent foods), dropping a search still on its way.
  void clear() {
    _latestRequest++;
    state = const SearchIdle();
  }
}
