import 'package:frontend/models/product_model.dart';

ProductModel buildProduct({
  String name = 'Bánh quy yến mạch',
  String brand = 'Thương hiệu mẫu',
  String barcode = '8934563138165',
  int? score = 72,
  double? calories = 412,
  double? protein = 9.8,
  double? fat = 14.2,
  double? carbs = 61.5,
  String deepThink = 'Yến mạch nguyên hạt cung cấp chất xơ.',
  String recommendation = 'Phù hợp làm bữa phụ.',
  List<String> declaredAllergens = const ['Gluten'],
  List<String> suggestedAllergens = const ['Sữa'],
  List<String> alternatives = const ['Hạt điều không muối'],
  String? aiError,
}) {
  return ProductModel(
    barcode: barcode,
    name: name,
    brand: brand,
    imageUrl: '',
    score: score,
    calories: calories,
    protein: protein,
    fat: fat,
    carbs: carbs,
    deepThink: score == null ? '' : deepThink,
    recommendation: score == null ? '' : recommendation,
    declaredAllergens: declaredAllergens,
    suggestedAllergens: score == null ? const [] : suggestedAllergens,
    alternatives: score == null ? const [] : alternatives,
    aiError: score == null ? (aiError ?? 'AI_UNAVAILABLE') : null,
  );
}
