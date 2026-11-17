import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A search another feature asks the search tab to run (a food recognized in a photo). Compared by identity, so
/// asking for the same words twice still runs twice.
final class SearchRequest {
  SearchRequest(this.query, {this.englishQuery});

  final String query;

  /// English words for USDA (its names are English only), e.g. "tomato" for "cà chua".
  final String? englishQuery;
}

final searchRequestProvider = NotifierProvider<SearchRequestNotifier, SearchRequest?>(SearchRequestNotifier.new);

class SearchRequestNotifier extends Notifier<SearchRequest?> {
  @override
  SearchRequest? build() => null;

  void request(String query, {String? englishQuery}) => state = SearchRequest(query, englishQuery: englishQuery);

  void clear() => state = null;
}
