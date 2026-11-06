import 'package:flutter/foundation.dart';

import '../../models/product_summary.dart';

/// Scan and search history for the current app session only. It lives in
/// memory, is never written to disk or sent anywhere, and is gone when the
/// app closes. Keeping it after a restart requires signing in (not built yet).
class SessionHistory extends ChangeNotifier {
  static const int maxEntries = 20;

  final List<ProductSummary> _scans = [];
  final List<String> _searches = [];

  List<ProductSummary> get scans => List.unmodifiable(_scans);

  List<String> get searches => List.unmodifiable(_searches);

  void addScan(ProductSummary product) {
    final String key = _keyOf(product);
    _scans
      ..removeWhere((entry) => _keyOf(entry) == key)
      ..insert(0, product);
    _trim(_scans);
    notifyListeners();
  }

  void addSearch(String query) {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final String key = trimmed.toLowerCase();
    _searches
      ..removeWhere((entry) => entry.toLowerCase() == key)
      ..insert(0, trimmed);
    _trim(_searches);
    notifyListeners();
  }

  void clearScans() {
    if (_scans.isEmpty) return;
    _scans.clear();
    notifyListeners();
  }

  void clearSearches() {
    if (_searches.isEmpty) return;
    _searches.clear();
    notifyListeners();
  }

  static String _keyOf(ProductSummary product) {
    return product.barcode.isNotEmpty
        ? product.barcode
        : (product.name ?? '').toLowerCase();
  }

  static void _trim(List<Object> entries) {
    if (entries.length > maxEntries) {
      entries.removeRange(maxEntries, entries.length);
    }
  }
}
