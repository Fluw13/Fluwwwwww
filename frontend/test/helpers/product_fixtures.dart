import 'package:frontend/models/fns_result.dart';
import 'package:frontend/models/product_model.dart';

/// A backend FNS result; `score: null` gives a NOT_SCORED result with a missing-data reason.
FnsResult buildFns({double? score = 7.8, String category = 'C2'}) {
  if (score == null) {
    return const FnsResult(
      status: FnsStatus.notScored,
      reasonCodes: ['BASELINE_NUTRIENT_MISSING'],
      missingFields: ['sodium_mg'],
    );
  }
  return FnsResult(
    status: FnsStatus.provisional,
    score: score,
    category: category,
    basis: 'per_100g',
    rawScore: -3,
    baselineComponents: const ['energy', 'saturated_fat', 'total_sugars', 'sodium'],
    componentPoints: const {
      'energy': 4,
      'saturated_fat': 1,
      'total_sugars': 2,
      'sodium': 3,
      'fvnl': 0,
      'protein': 5,
      'fiber': 8,
    },
    proteinEligible: true,
    fiberEligible: true,
    limitations: const ['RULES_NEEDS_REVIEW', 'SOURCE_UNVERIFIED'],
  );
}

/// `aiError` set means the backend returned no AI explanation; the score is independent of it.
ProductModel buildProduct({
  String name = 'Bánh quy yến mạch',
  String brand = 'Thương hiệu mẫu',
  String barcode = '8934563138165',
  double? score = 7.8,
  FnsResult? fns,
  double? calories = 412,
  double? protein = 9.8,
  double? fat = 14.2,
  double? carbs = 61.5,
  double? sugars = 12,
  String deepThink = 'Yến mạch nguyên hạt cung cấp chất xơ.',
  String recommendation = 'Phù hợp làm bữa phụ.',
  List<String> declaredAllergens = const ['Gluten'],
  List<String> suggestedAllergens = const ['Sữa'],
  String? aiError,
}) {
  final bool hasAnalysis = aiError == null;
  return ProductModel(
    barcode: barcode,
    name: name,
    brand: brand,
    imageUrl: '',
    fns: fns ?? buildFns(score: score),
    calories: calories,
    protein: protein,
    fat: fat,
    carbs: carbs,
    sugars: sugars,
    deepThink: hasAnalysis ? deepThink : '',
    recommendation: hasAnalysis ? recommendation : '',
    declaredAllergens: declaredAllergens,
    suggestedAllergens: hasAnalysis ? suggestedAllergens : const [],
    aiError: aiError,
  );
}
