import '../../data/json/json_fields.dart';

enum IndicatorEffect {
  negative,
  positive;

  static IndicatorEffect? fromCode(String? code) => switch (code) {
    'negative' => negative,
    'positive' => positive,
    _ => null,
  };
}

enum IndicatorStatus {
  counted,
  excludedByRule,
  estimated;

  static IndicatorStatus? fromCode(String? code) => switch (code) {
    'counted' => counted,
    'excluded_by_rule' => excludedByRule,
    'estimated' => estimated,
    _ => null,
  };
}

/// Threshold interval that contains the value. A null bound is open-ended.
class IndicatorRange {
  const IndicatorRange({
    this.min,
    this.minInclusive,
    this.max,
    this.maxInclusive,
  });

  static IndicatorRange? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    if (json == null) return null;
    final IndicatorRange range = IndicatorRange(
      min: readDouble(json['min']),
      minInclusive: readBool(json['minInclusive']),
      max: readDouble(json['max']),
      maxInclusive: readBool(json['maxInclusive']),
    );
    return range.min == null && range.max == null ? null : range;
  }

  final double? min;
  final bool? minInclusive;
  final double? max;
  final bool? maxInclusive;
}

/// One row of the nutrition score table.
class ScoreIndicator {
  const ScoreIndicator({
    required this.label,
    this.key,
    this.effect,
    this.value,
    this.unit,
    this.per,
    this.points,
    this.maxPoints,
    this.range,
    this.status,
    this.note,
  });

  static ScoreIndicator? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    final String? label = readString(json?['label']);
    if (json == null || label == null) return null;

    return ScoreIndicator(
      key: readString(json['key']),
      label: label,
      effect: IndicatorEffect.fromCode(readString(json['effect'])),
      value: readDouble(json['value']),
      unit: readString(json['unit']),
      per: readString(json['per']),
      points: readInt(json['points']),
      maxPoints: readInt(json['maxPoints']),
      range: IndicatorRange.tryParse(json['range']),
      status: IndicatorStatus.fromCode(readString(json['status'])),
      note: readString(json['note']),
    );
  }

  final String? key;
  final String label;
  final IndicatorEffect? effect;
  final double? value;

  /// "kJ", "g", "%" or "count".
  final String? unit;

  /// "100g", "100ml" or null when the value is not per 100.
  final String? per;
  final int? points;
  final int? maxPoints;
  final IndicatorRange? range;
  final IndicatorStatus? status;
  final String? note;
}
