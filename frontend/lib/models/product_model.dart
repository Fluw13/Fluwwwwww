class ProductModel {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final bool hasAiAnalysis;
  final int score;
  final String scoreRating;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String deepThink;
  final String recommendation;
  final String? disclaimer;
  final List<String> allergens;
  final List<String> alternatives;

  ProductModel({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.hasAiAnalysis,
    required this.score,
    required this.scoreRating,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.deepThink,
    required this.recommendation,
    required this.disclaimer,
    required this.allergens,
    required this.alternatives,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseScore(dynamic value) {
    final num? parsed = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (parsed == null || !parsed.isFinite) return 0;
    return parsed.round().clamp(0, 100).toInt();
  }

  static String? _readOptionalText(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  static bool _readHasAiAnalysis(Map<String, dynamic> json) {
    final dynamic aiAvailable = json['aiAvailable'];
    final bool hasAnalysisObject = json['aiAnalysis'] is Map;
    if (aiAvailable is bool) return aiAvailable && hasAnalysisObject;
    return hasAnalysisObject;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final dynamic rawAi = json['aiAnalysis'];
    final Map<String, dynamic> ai = rawAi is Map ? Map<String, dynamic>.from(rawAi) : <String, dynamic>{};
    final nutrients = product['nutriments'] ?? {};

    return ProductModel(
      barcode: json['barcode'] ?? '',
      name: product['product_name'] ?? 'Sản phẩm chưa có tên',
      brand: product['brands'] ?? 'Chưa rõ thương hiệu',
      imageUrl: product['image_front_url'] ?? '',
      hasAiAnalysis: _readHasAiAnalysis(json),
      score: _parseScore(ai['score']),
      scoreRating: _readOptionalText(ai['scoreRating']) ?? '',
      calories: _parseDouble(nutrients['energy-kcal_100g'] ?? nutrients['energy-kcal']),
      protein: _parseDouble(nutrients['proteins_100g'] ?? nutrients['proteins']),
      fat: _parseDouble(nutrients['fat_100g'] ?? nutrients['fat']),
      carbs: _parseDouble(nutrients['carbohydrates_100g'] ?? nutrients['carbohydrates']),
      deepThink: _readOptionalText(ai['deepThink']) ?? '',
      recommendation: _readOptionalText(ai['recommendation']) ?? '',
      disclaimer: _readOptionalText(ai['disclaimer']),
      allergens: List<String>.from(ai['allergens'] ?? []),
      alternatives: List<String>.from(ai['alternatives'] ?? []),
    );
  }
}
