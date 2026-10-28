class ProductModel {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final int score;
  final String scoreRating;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String deepThink;
  final String recommendation;
  final List<String> allergens;
  final List<String> alternatives;

  ProductModel({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.score,
    required this.scoreRating,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.deepThink,
    required this.recommendation,
    required this.allergens,
    required this.alternatives,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final ai = json['aiAnalysis'] ?? {};
    final nutrients = product['nutriments'] ?? {};

    return ProductModel(
      barcode: json['barcode'] ?? '',
      name: product['product_name'] ?? 'Sản phẩm chưa có tên',
      brand: product['brands'] ?? 'Chưa rõ thương hiệu',
      imageUrl: product['image_front_url'] ?? '',
      score: (ai['score'] is int) ? ai['score'] : int.tryParse(ai['score']?.toString() ?? '50') ?? 50,
      scoreRating: ai['scoreRating'] ?? 'Trung bình',
      calories: _parseDouble(nutrients['energy-kcal_100g'] ?? nutrients['energy-kcal']),
      protein: _parseDouble(nutrients['proteins_100g'] ?? nutrients['proteins']),
      fat: _parseDouble(nutrients['fat_100g'] ?? nutrients['fat']),
      carbs: _parseDouble(nutrients['carbohydrates_100g'] ?? nutrients['carbohydrates']),
      deepThink: ai['deepThink'] ?? 'Zero đang phân tích thành phần dinh dưỡng...',
      recommendation: ai['recommendation'] ?? 'Sử dụng ở mức độ vừa phải.',
      allergens: List<String>.from(ai['allergens'] ?? []),
      alternatives: List<String>.from(ai['alternatives'] ?? []),
    );
  }
}
