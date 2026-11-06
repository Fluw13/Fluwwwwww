import 'package:frontend/models/product_summary.dart';
import 'package:frontend/models/score_level.dart';

import 'fake_backend.dart';

/// Barcode of the `product-food-complete` contract fixture.
const String sampleBarcode = '8930000000019';

/// A list entry as the app builds it from API v1 data.
ProductSummary sampleSummary({
  String barcode = sampleBarcode,
  String? name = 'Sữa chua',
  String? brand = 'Hãng',
  int? score = 64,
  ScoreLevel? level = ScoreLevel.moderate,
  String? levelLabel = 'Trung bình',
  double? calories = 120,
}) {
  return ProductSummary(
    barcode: barcode,
    name: name,
    brand: brand,
    score: score,
    level: level,
    levelLabel: levelLabel,
    calories: calories,
  );
}

/// Answers every product with `product-food-complete` and every search with
/// `search-results`; the requests it got are in [FakeBackend.requests].
FakeBackend productBackend() {
  return FakeBackend(
    product: (_) => FakeBackend.fixture('product-food-complete'),
    search: (_) => FakeBackend.fixture('search-results'),
  );
}

extension FakeBackendRequests on FakeBackend {
  Iterable<Uri> get productRequests =>
      requests.where((url) => url.path.startsWith('/api/v1/products/'));

  Iterable<Uri> get searchRequests =>
      requests.where((url) => url.path == '/api/v1/search');
}
