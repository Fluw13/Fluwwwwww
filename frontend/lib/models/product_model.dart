import 'score_level.dart';

class ProductModel {
  const ProductModel({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.score,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.deepThink,
    required this.recommendation,
    required this.declaredAllergens,
    required this.suggestedAllergens,
    required this.alternatives,
  });

  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final int score;
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final String deepThink;
  final String recommendation;
  final List<String> declaredAllergens;
  final List<String> suggestedAllergens;
  final List<String> alternatives;

  ScoreLevel get level => ScoreLevel.fromScore(score);

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final product = _asMap(json['product']);
    final analysis = _asMap(json['aiAnalysis']);
    final nutriments = _asMap(product['nutriments']);

    final List<String> declaredAllergens = _toStringList(product['allergens']);
    final Set<String> declaredKeys = declaredAllergens.map((name) => name.toLowerCase()).toSet();

    final Object? rawScore = analysis['score'];
    if (rawScore is! num) {
      throw const FormatException('Phản hồi thiếu điểm sức khỏe.');
    }

    return ProductModel(
      barcode: json['barcode'] as String? ?? '',
      name: product['product_name'] as String? ?? 'Sản phẩm chưa có tên',
      brand: product['brands'] as String? ?? 'Chưa rõ thương hiệu',
      imageUrl: product['image_front_url'] as String? ?? '',
      score: rawScore.round().clamp(0, 100).toInt(),
      calories: _toDouble(nutriments['energy-kcal']),
      protein: _toDouble(nutriments['proteins']),
      fat: _toDouble(nutriments['fat']),
      carbs: _toDouble(nutriments['carbohydrates']),
      deepThink: analysis['deepThink'] as String? ?? '',
      recommendation: analysis['recommendation'] as String? ?? '',
      declaredAllergens: declaredAllergens,
      suggestedAllergens: _toStringList(analysis['allergens'])
          .where((name) => !declaredKeys.contains(name.toLowerCase()))
          .toList(),
      alternatives: _toStringList(analysis['alternatives']),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    return value is Map<String, dynamic> ? value : const {};
  }

  static double? _toDouble(Object? value) {
    return value is num ? value.toDouble() : null;
  }

  static List<String> _toStringList(Object? value) {
    return value is List ? value.map((item) => item.toString()).toList() : const [];
  }
}
