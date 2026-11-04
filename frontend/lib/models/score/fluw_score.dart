import '../../data/json/json_fields.dart';
import '../score_level.dart';
import 'additives_score.dart';
import 'missing_item.dart';
import 'nutrition_score.dart';

/// `score` from `GET /api/v1/products/:barcode`, computed by the backend.
/// The app shows these numbers as they are and never recomputes them.
class FluwScore {
  const FluwScore({
    this.version,
    this.nutritionWeight,
    this.additivesWeight,
    this.total = const ScoreTotal(),
    this.nutrition = const NutritionScore(),
    this.additives = const AdditivesScore(),
    this.missing = const [],
    this.disclaimer,
  });

  factory FluwScore.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? weights = readMap(json['weights']);
    return FluwScore(
      version: readString(json['version']),
      nutritionWeight: readDouble(weights?['nutrition']),
      additivesWeight: readDouble(weights?['additives']),
      total: ScoreTotal.fromJson(readMap(json['total'])),
      nutrition: NutritionScore.fromJson(readMap(json['nutrition'])),
      additives: AdditivesScore.fromJson(readMap(json['additives'])),
      missing: readList(json['missing'], MissingItem.tryParse),
      disclaimer: readString(json['disclaimer']),
    );
  }

  /// Formula version, e.g. "fluw-score-1.0".
  final String? version;

  /// 0.7 means 70 %.
  final double? nutritionWeight;
  final double? additivesWeight;
  final ScoreTotal total;
  final NutritionScore nutrition;
  final AdditivesScore additives;

  /// Everything still missing, merged from both component scores.
  final List<MissingItem> missing;
  final String? disclaimer;
}

class ScoreTotal {
  const ScoreTotal({this.value, this.level, this.label, this.calculation});

  factory ScoreTotal.fromJson(Map<String, dynamic>? json) {
    return ScoreTotal(
      value: readInt(json?['value']),
      level: ScoreLevel.fromCode(readString(json?['level'])),
      label: readString(json?['label']),
      calculation: ScoreCalculation.tryParse(json?['calculation']),
    );
  }

  /// 0–100, null when one of the component scores is missing.
  final int? value;
  final ScoreLevel? level;

  /// Level text chosen by the backend, e.g. "Nên hạn chế".
  final String? label;
  final ScoreCalculation? calculation;

  bool get isAvailable => value != null;
}

/// Weighted parts of the total, so the app can print the sum without
/// computing it.
class ScoreCalculation {
  const ScoreCalculation({
    this.nutritionWeighted,
    this.additivesWeighted,
    this.sum,
  });

  static ScoreCalculation? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    if (json == null) return null;
    return ScoreCalculation(
      nutritionWeighted: readDouble(json['nutritionWeighted']),
      additivesWeighted: readDouble(json['additivesWeighted']),
      sum: readDouble(json['sum']),
    );
  }

  final double? nutritionWeighted;
  final double? additivesWeighted;

  /// Unrounded sum; the total is this value rounded.
  final double? sum;
}
