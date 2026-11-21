import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/search/data/search_providers.dart';
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
    try {
      final response = await ref.read(foodApiProvider).search(query, englishQuery: usdaQuery);
      if (request == _latestRequest) {
        state = SearchLoaded(response, englishQuery: usdaQuery);
      }
    } on ApiFailure catch (failure) {
      if (request == _latestRequest) {
        state = SearchFailed(query, failure, englishQuery: usdaQuery);
      }
    }
  }

  /// Back to the empty screen (recent foods), dropping a search still on its way.
  void clear() {
    _latestRequest++;
    state = const SearchIdle();
  }
}
