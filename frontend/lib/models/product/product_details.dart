import '../../data/json/json_fields.dart';
import '../score/fluw_score.dart';
import 'product.dart';

/// Body of `GET /api/v1/products/:barcode`.
class ProductDetails {
  const ProductDetails({required this.product, required this.score});

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      product: Product.fromJson(requireMap(json, 'product')),
      score: FluwScore.fromJson(requireMap(json, 'score')),
    );
  }

  final Product product;
  final FluwScore score;
}
