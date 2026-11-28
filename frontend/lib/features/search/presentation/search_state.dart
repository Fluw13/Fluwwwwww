import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/search/domain/search_response.dart';

sealed class SearchState {
  const SearchState();
}

final class SearchIdle extends SearchState {
  const SearchIdle();
}

final class SearchLoading extends SearchState {
  const SearchLoading(this.query);

  final String query;
}

final class SearchLoaded extends SearchState {
  const SearchLoaded(this.response, {this.englishQuery, this.failure});

  final SearchResponse response;

  /// The English words USDA was searched with, shown so the user knows where its results come from.
  final String? englishQuery;

  /// Set when the sources failed and only the user's own products answered, so the screen can say why and retry.
  final ApiFailure? failure;
}

final class SearchFailed extends SearchState {
  const SearchFailed(this.query, this.failure, {this.englishQuery});

  final String query;
  final ApiFailure failure;

  /// Kept so "Thử lại" searches USDA with the same English words.
  final String? englishQuery;
}
