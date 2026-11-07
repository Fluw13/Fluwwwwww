import 'product_model.dart';

/// The few fields a product list needs, so lists never depend on the full detail payload.
class ProductSummary {
  const ProductSummary({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    this.score,
    this.calories,
  });

  factory ProductSummary.fromProduct(ProductModel product) {
    return ProductSummary(
      barcode: product.barcode,
      name: product.name,
      brand: product.brand,
      imageUrl: product.imageUrl,
      score: product.score,
      calories: product.calories,
    );
  }

  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;

  /// Fluw Nutrition Score (0-10); null when the product is not scored.
  final double? score;
  final double? calories;
}
