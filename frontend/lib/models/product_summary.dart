import 'product/product_details.dart';
import 'score_level.dart';

/// The few fields a product list needs, so lists never depend on the full
/// detail payload. Built from API v1 data; the score is the backend's total
/// and stays null when the backend could not compute it.
class ProductSummary {
  const ProductSummary({
    required this.barcode,
    this.name,
    this.brand,
    this.imageUrl,
    this.score,
    this.level,
    this.levelLabel,
    this.calories,
  });

  factory ProductSummary.fromDetails(ProductDetails details) {
    return ProductSummary(
      barcode: details.product.barcode,
      name: details.product.name,
      brand: details.product.brand,
      imageUrl: details.product.images.front?.preview,
      score: details.score.total.value,
      level: details.score.total.level,
      levelLabel: details.score.total.label,
      calories: details.product.nutrition.per100?.energyKcal,
    );
  }

  final String barcode;
  final String? name;
  final String? brand;

  /// Already restricted to the Open Food Facts image hosts.
  final String? imageUrl;

  /// `score.total.value`, null when there was not enough data.
  final int? score;
  final ScoreLevel? level;

  /// Level text chosen by the backend, e.g. "Nên hạn chế".
  final String? levelLabel;

  /// Per 100 g or 100 ml.
  final double? calories;
}
