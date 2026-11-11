import 'package:fluw/core/nutrition/nutrient.dart';

/// A missing key means the source has no data for that nutrient; it is never treated as 0.
final class Nutrients {
  Nutrients(Map<Nutrient, double> values) : _values = Map.unmodifiable(values) {
    for (final MapEntry(key: nutrient, :value) in values.entries) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError.value(value, nutrient.name, 'Phải là số không âm');
      }
    }
  }

  final Map<Nutrient, double> _values;

  double? operator [](Nutrient nutrient) => _values[nutrient];

  Nutrients scaled(double factor) =>
      Nutrients({for (final MapEntry(key: nutrient, :value) in _values.entries) nutrient: value * factor});
}
