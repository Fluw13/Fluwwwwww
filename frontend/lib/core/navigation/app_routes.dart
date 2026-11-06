import 'package:flutter/material.dart';

import '../../screens/product_detail_screen.dart';
import '../../screens/search_results_screen.dart';
import '../search/search_input.dart';
import 'product_origin.dart';

/// Single place that decides which screen opens a product or a search, so
/// home, history, search results and the scanner always lead to the same
/// screens.
class AppRoutes {
  const AppRoutes._();

  static Future<void> openProduct(
    BuildContext context,
    String barcode, {
    required ProductOrigin origin,
    bool replace = false,
  }) {
    final MaterialPageRoute<void> route = MaterialPageRoute(
      builder: (_) => ProductDetailScreen(barcode: barcode, origin: origin),
    );
    return replace
        ? Navigator.pushReplacement(context, route)
        : Navigator.push(context, route);
  }

  static Future<void> openSearch(BuildContext context, String query) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchResultsScreen(query: query)),
    );
  }

  /// Opens what a search-box entry leads to: a barcode opens the product, a
  /// keyword opens the results. Returns false when [input] opens nothing.
  static bool openSearchInput(BuildContext context, SearchInput input) {
    switch (input) {
      case BarcodeSearchInput(:final String barcode):
        openProduct(context, barcode, origin: ProductOrigin.search);
        return true;
      case KeywordSearchInput(:final String query):
        openSearch(context, query);
        return true;
      case EmptySearchInput() || InvalidSearchInput():
        return false;
    }
  }
}
