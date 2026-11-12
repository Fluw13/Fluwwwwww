enum BmiCategory { underweight, normal, overweight, obese }

/// Asian BMI scale. The value is truncated (not rounded) to 0.1 so the shown number keeps the exact spec thresholds:
/// 22.96 shows "22.9" and stays normal, instead of showing "23.0" next to a normal label.
final class Bmi {
  factory Bmi.fromMeasurements({required double weightKg, required double heightCm}) {
    final heightM = heightCm / 100;
    // The tiny epsilon keeps 23.0 computed as 22.999999999 from dropping to 22.9.
    final tenths = (weightKg / (heightM * heightM) * 10 + 1e-9).floor();
    final category = switch (tenths) {
      < 185 => BmiCategory.underweight,
      < 230 => BmiCategory.normal,
      < 250 => BmiCategory.overweight,
      _ => BmiCategory.obese,
    };
    return Bmi._(tenths / 10, category);
  }

  const Bmi._(this.displayValue, this.category);

  /// Truncated to 0.1; show this number so the label always matches it.
  final double displayValue;
  final BmiCategory category;
}
