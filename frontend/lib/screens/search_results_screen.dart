import 'package:flutter/material.dart';

import '../core/navigation/app_routes.dart';
import '../data/api/api_cancel_token.dart';
import '../data/api/fluw_api_client.dart';
import '../data/api/fluw_api_scope.dart';
import '../models/search/search_results.dart';
import '../widgets/async/api_error_view.dart';
import '../widgets/async/async_content.dart';
import '../widgets/search/search_results_list.dart';
import '../widgets/search/search_results_loading_view.dart';

/// Results of one search the user submitted. The request is sent once on open
/// and again only when the user taps retry; it is aborted when the screen closes.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.query});

  final String query;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ApiCancelToken _cancelToken = ApiCancelToken();
  late FluwApiClient _client;
  Future<SearchResults>? _results;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _client = FluwApiScope.of(context);
    _results ??= _search();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  Future<SearchResults> _search() =>
      _client.search(widget.query, cancelToken: _cancelToken);

  void _retry() {
    setState(() {
      _results = _search();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả tìm kiếm')),
      body: AsyncContent<SearchResults>(
        future: _results!,
        loadingBuilder: (_) => SearchResultsLoadingView(query: widget.query),
        errorBuilder: (_, error) => ApiErrorView(error: error, onRetry: _retry),
        dataBuilder: (context, results) => SearchResultsList(
          query: widget.query,
          results: results,
          onOpen: (item) => AppRoutes.openProduct(context, item.barcode),
        ),
      ),
    );
  }
}
