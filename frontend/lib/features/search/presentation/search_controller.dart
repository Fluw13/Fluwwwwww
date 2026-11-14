import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/search/data/search_providers.dart';
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

  Future<void> search(String rawQuery) async {
    final query = normalizeQuery(rawQuery);
    if (query.length < minSearchLength || query.length > maxSearchLength) {
      return;
    }
    final request = ++_latestRequest;
    state = SearchLoading(query);
    try {
      final response = await ref.read(foodApiProvider).search(query);
      if (request == _latestRequest) {
        state = SearchLoaded(response);
      }
    } on ApiFailure catch (failure) {
      if (request == _latestRequest) {
        state = SearchFailed(query, failure);
      }
    }
  }

  void clear() {
    _latestRequest++;
    state = const SearchIdle();
  }
}
