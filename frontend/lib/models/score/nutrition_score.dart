import '../../data/json/json_fields.dart';
import 'missing_item.dart';
import 'score_indicator.dart';

enum NutritionStatus {
  computed,
  missingData,
  needsPreparedData,
  notApplicable;

  static NutritionStatus? fromCode(String? code) => switch (code) {
    'computed' => computed,
    'missing_data' => missingData,
    'needs_prepared_data' => needsPreparedData,
    'not_applicable' => notApplicable,
    _ => null,
  };
}

enum NutritionScoreBasis {
  asSold,
  prepared;

  static NutritionScoreBasis? fromCode(String? code) => switch (code) {
    'as_sold' => asSold,
    'prepared' => prepared,
    _ => null,
  };
}

/// Raw-point interval and the 0–100 interval it maps to.
class NutritionBand {
  const NutritionBand({
    this.pointsMin,
    this.pointsMax,
    this.scoreMin,
    this.scoreMax,
  });

  static NutritionBand? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    if (json == null) return null;
    return NutritionBand(
      pointsMin: readInt(json['pointsMin']),
      pointsMax: readInt(json['pointsMax']),
      scoreMin: readInt(json['scoreMin']),
      scoreMax: readInt(json['scoreMax']),
    );
  }

  final int? pointsMin;
  final int? pointsMax;
  final int? scoreMin;
  final int? scoreMax;
}

class NutritionScore {
  const NutritionScore({
    this.value,
    this.status,
    this.productType,
    this.productTypeLabel,
    this.basis,
    this.points,
    this.negativePoints,
    this.positivePoints,
    this.band,
    this.indicators = const [],
    this.missing = const [],
  });

  factory NutritionScore.fromJson(Map<String, dynamic>? json) {
    return NutritionScore(
      value: readInt(json?['value']),
      status: NutritionStatus.fromCode(readString(json?['status'])),
      productType: readString(json?['productType']),
      productTypeLabel: readString(json?['productTypeLabel']),
      basis: NutritionScoreBasis.fromCode(readString(json?['basis'])),
      points: readInt(json?['points']),
      negativePoints: readInt(json?['negativePoints']),
      positivePoints: readInt(json?['positivePoints']),
      band: NutritionBand.tryParse(json?['band']),
      indicators: readList(json?['indicators'], ScoreIndicator.tryParse),
      missing: readList(json?['missing'], MissingItem.tryParse),
    );
  }

  /// 0–100, null when not computed.
  final int? value;
  final NutritionStatus? status;

  /// "food", "beverage", "water", ... as decided by the backend.
  final String? productType;
  final String? productTypeLabel;
  final NutritionScoreBasis? basis;

  /// Raw points = negative points − positive points.
  final int? points;
  final int? negativePoints;
  final int? positivePoints;
  final NutritionBand? band;
  final List<ScoreIndicator> indicators;
  final List<MissingItem> missing;
}
