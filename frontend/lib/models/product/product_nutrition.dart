import '../../data/json/json_fields.dart';

enum NutritionBasis {
  per100g,
  per100ml;

  static NutritionBasis? fromCode(String? code) => switch (code) {
    '100g' => per100g,
    '100ml' => per100ml,
    _ => null,
  };
}

/// Values per 100 g or 100 ml. Null means Open Food Facts has no value; it is
/// never replaced by 0.
class NutrientValues {
  const NutrientValues({
    this.energyKcal,
    this.energyKj,
    this.fat,
    this.saturatedFat,
    this.carbohydrates,
    this.sugars,
    this.fiber,
    this.proteins,
    this.salt,
  });

  static NutrientValues? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    if (json == null) return null;
    return NutrientValues(
      energyKcal: readDouble(json['energyKcal']),
      energyKj: readDouble(json['energyKj']),
      fat: readDouble(json['fat']),
      saturatedFat: readDouble(json['saturatedFat']),
      carbohydrates: readDouble(json['carbohydrates']),
      sugars: readDouble(json['sugars']),
      fiber: readDouble(json['fiber']),
      proteins: readDouble(json['proteins']),
      salt: readDouble(json['salt']),
    );
  }

  final double? energyKcal;
  final double? energyKj;
  final double? fat;
  final double? saturatedFat;
  final double? carbohydrates;
  final double? sugars;
  final double? fiber;
  final double? proteins;
  final double? salt;
}

class ProductNutrition {
  const ProductNutrition({this.basis, this.per100, this.preparedPer100});

  factory ProductNutrition.fromJson(Map<String, dynamic>? json) {
    return ProductNutrition(
      basis: NutritionBasis.fromCode(readString(json?['basis'])),
      per100: NutrientValues.tryParse(json?['per100']),
      preparedPer100: NutrientValues.tryParse(json?['preparedPer100']),
    );
  }

  final NutritionBasis? basis;
  final NutrientValues? per100;

  /// Values after preparation (instant noodles, powders), when known.
  final NutrientValues? preparedPer100;
}
