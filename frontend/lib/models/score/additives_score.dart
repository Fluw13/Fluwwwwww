import '../../data/json/json_fields.dart';
import 'missing_item.dart';

enum AdditivesStatus {
  computed,
  missingIngredients,
  ingredientsNotRecognized;

  static AdditivesStatus? fromCode(String? code) => switch (code) {
    'computed' => computed,
    'missing_ingredients' => missingIngredients,
    'ingredients_not_recognized' => ingredientsNotRecognized,
    _ => null,
  };
}

/// Additive-count interval that gives [score]. [countMax] is null for the
/// open-ended last band ("10 or more").
class AdditivesBand {
  const AdditivesBand({this.countMin, this.countMax, this.score});

  static AdditivesBand? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    if (json == null) return null;
    return AdditivesBand(
      countMin: readInt(json['countMin']),
      countMax: readInt(json['countMax']),
      score: readInt(json['score']),
    );
  }

  final int? countMin;
  final int? countMax;
  final int? score;
}

class AdditivesScore {
  const AdditivesScore({
    this.value,
    this.status,
    this.count,
    this.band,
    this.missing = const [],
  });

  factory AdditivesScore.fromJson(Map<String, dynamic>? json) {
    return AdditivesScore(
      value: readInt(json?['value']),
      status: AdditivesStatus.fromCode(readString(json?['status'])),
      count: readInt(json?['count']),
      band: AdditivesBand.tryParse(json?['band']),
      missing: readList(json?['missing'], MissingItem.tryParse),
    );
  }

  /// 0–100, null when not computed.
  final int? value;
  final AdditivesStatus? status;
  final int? count;
  final AdditivesBand? band;
  final List<MissingItem> missing;
}
