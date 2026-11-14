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
  const SearchLoaded(this.response);

  final SearchResponse response;
}

final class SearchFailed extends SearchState {
  const SearchFailed(this.query, this.failure);

  final String query;
  final ApiFailure failure;
}
