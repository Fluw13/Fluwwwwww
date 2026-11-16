import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A search another feature asks the search tab to run (a food recognized in a photo). Compared by identity, so
/// asking for the same words twice still runs twice.
final class SearchRequest {
  SearchRequest(this.query);

  final String query;
}

final searchRequestProvider = NotifierProvider<SearchRequestNotifier, SearchRequest?>(SearchRequestNotifier.new);

class SearchRequestNotifier extends Notifier<SearchRequest?> {
  @override
  SearchRequest? build() => null;

  void request(String query) => state = SearchRequest(query);

  void clear() => state = null;
}
