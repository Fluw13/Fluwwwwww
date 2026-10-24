class ProductModel {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String ingredientsText;
  final String nutritionGrades;
  final String quantity;
  final String categories;

  ProductModel({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.ingredientsText,
    required this.nutritionGrades,
    required this.quantity,
    required this.categories,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sản phẩm chưa rõ tên',
      brand: json['brand']?.toString() ?? 'Chưa rõ thương hiệu',
      imageUrl: json['imageUrl']?.toString() ?? '',
      ingredientsText: json['ingredientsText']?.toString() ?? 'Chưa có thông tin thành phần',
      nutritionGrades: json['nutritionGrades']?.toString() ?? 'N/A',
      quantity: json['quantity']?.toString() ?? '',
      categories: json['categories']?.toString() ?? '',
    );
  }
}

class AiAnalysisModel {
  final int healthScore;
  final String ratingLabel;
  final String summary;
  final List<String> pros;
  final List<String> cons;
  final List<String> allergensWarning;
  final String dietaryAdvice;
  final List<String> alternatives;

  AiAnalysisModel({
    required this.healthScore,
    required this.ratingLabel,
    required this.summary,
    required this.pros,
    required this.cons,
    required this.allergensWarning,
    required this.dietaryAdvice,
    required this.alternatives,
  });

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) {
    return AiAnalysisModel(
      healthScore: json['healthScore'] is int ? json['healthScore'] : int.tryParse(json['healthScore']?.toString() ?? '50') ?? 50,
      ratingLabel: json['ratingLabel']?.toString() ?? 'Chưa có đánh giá',
      summary: json['summary']?.toString() ?? '',
      pros: (json['pros'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      cons: (json['cons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      allergensWarning: (json['allergensWarning'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      dietaryAdvice: json['dietaryAdvice']?.toString() ?? '',
      alternatives: (json['alternatives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ProductDetailResponse {
  final ProductModel product;
  final AiAnalysisModel aiAnalysis;

  ProductDetailResponse({
    required this.product,
    required this.aiAnalysis,
  });

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ProductDetailResponse(
      product: ProductModel.fromJson(data['product'] as Map<String, dynamic>? ?? {}),
      aiAnalysis: AiAnalysisModel.fromJson(data['aiAnalysis'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class SearchResultItem {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String nutritionGrades;

  SearchResultItem({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.nutritionGrades,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sản phẩm không có tên',
      brand: json['brand']?.toString() ?? 'Chưa rõ thương hiệu',
      imageUrl: json['imageUrl']?.toString() ?? '',
      nutritionGrades: json['nutritionGrades']?.toString() ?? 'N/A',
    );
  }
}
