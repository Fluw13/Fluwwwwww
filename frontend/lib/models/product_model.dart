import 'fns_result.dart';
import 'score_level.dart';

class ProductModel {
  const ProductModel({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.fns,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.saturatedFat,
    this.sugars,
    this.fiber,
    this.sodiumMg,
    required this.deepThink,
    required this.recommendation,
    required this.declaredAllergens,
    required this.suggestedAllergens,
    this.aiError,
  });

  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final FnsResult fns;
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final double? saturatedFat;
  final double? sugars;
  final double? fiber;
  final double? sodiumMg;
  final String deepThink;
  final String recommendation;
  final List<String> declaredAllergens;
  final List<String> suggestedAllergens;

  /// Null when the backend returned an AI explanation; otherwise why it is missing.
  final String? aiError;

  /// Fluw Nutrition Score (0-10); null when the product is not scored.
  double? get score => fns.isScored ? fns.score : null;

  ScoreLevel? get level => fns.level;

  /// The AI explanation is optional and independent of the score.
  bool get hasAnalysis => aiError == null;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final product = _asMap(json['product']);
    final nutriments = _asMap(product['nutriments']);
    final Object? rawAnalysis = json['aiAnalysis'];
    final bool hasAnalysis = rawAnalysis is Map<String, dynamic>;
    final Map<String, dynamic> analysis = hasAnalysis ? rawAnalysis : const {};

    final List<String> declaredAllergens = _toStringList(product['allergens']);
    final Set<String> declaredKeys = declaredAllergens.map((name) => name.toLowerCase()).toSet();

    final Object? rawAiError = json['aiError'];
    final String? aiError = hasAnalysis
        ? null
        : (rawAiError is String && rawAiError.isNotEmpty ? rawAiError : 'AI_UNAVAILABLE');
    final double? sodiumGrams = _toDouble(nutriments['sodium']);

    return ProductModel(
      barcode: json['barcode'] as String? ?? '',
      name: product['product_name'] as String? ?? 'Sản phẩm chưa có tên',
      brand: product['brands'] as String? ?? 'Chưa rõ thương hiệu',
      imageUrl: product['image_front_url'] as String? ?? '',
      fns: FnsResult.fromJson(json['fns']),
      calories: _toDouble(nutriments['energy-kcal']),
      protein: _toDouble(nutriments['proteins']),
      fat: _toDouble(nutriments['fat']),
      carbs: _toDouble(nutriments['carbohydrates']),
      saturatedFat: _toDouble(nutriments['saturated-fat']),
      sugars: _toDouble(nutriments['sugars']),
      fiber: _toDouble(nutriments['fiber']),
      sodiumMg: sodiumGrams == null ? null : sodiumGrams * 1000,
      deepThink: analysis['deepThink'] as String? ?? '',
      recommendation: analysis['recommendation'] as String? ?? '',
      declaredAllergens: declaredAllergens,
      suggestedAllergens: _toStringList(analysis['allergens'])
          .where((name) => !declaredKeys.contains(name.toLowerCase()))
          .toList(),
      aiError: aiError,
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
