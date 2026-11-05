import 'package:flutter/material.dart';

import '../../screens/product_detail_screen.dart';
import '../../screens/search_results_screen.dart';

/// Single place that decides which screen opens a product or a search, so
/// home, search results and the scanner always lead to the same screens.
class AppRoutes {
  const AppRoutes._();

  static Future<void> openProduct(
    BuildContext context,
    String barcode, {
    bool replace = false,
  }) {
    final MaterialPageRoute<void> route = MaterialPageRoute(
      builder: (_) => ProductDetailScreen(barcode: barcode),
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
}
