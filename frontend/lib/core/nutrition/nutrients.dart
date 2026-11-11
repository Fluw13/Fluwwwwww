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

  Map<Nutrient, double> asMap() => _values;

  Nutrients scaled(double factor) =>
      Nutrients({for (final MapEntry(key: nutrient, :value) in _values.entries) nutrient: value * factor});

  @override
  bool operator ==(Object other) =>
      other is Nutrients &&
      other._values.length == _values.length &&
      _values.entries.every((entry) => other._values[entry.key] == entry.value);

  @override
  int get hashCode => Object.hashAllUnordered(_values.entries.map((entry) => Object.hash(entry.key, entry.value)));
}
