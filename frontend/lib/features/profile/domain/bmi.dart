enum BmiCategory { underweight, normal, overweight, obese }

/// Asian BMI scale. Classified on the value rounded to 0.1, the number the UI shows, so 22.95 shown as "23.0" is not
/// labelled normal.
final class Bmi {
  factory Bmi.fromMeasurements({required double weightKg, required double heightCm}) {
    final heightM = heightCm / 100;
    final tenths = (weightKg / (heightM * heightM) * 10).round();
    final category = switch (tenths) {
      < 185 => BmiCategory.underweight,
      < 230 => BmiCategory.normal,
      < 250 => BmiCategory.overweight,
      _ => BmiCategory.obese,
    };
    return Bmi._(tenths / 10, category);
  }

  const Bmi._(this.roundedValue, this.category);

  /// Already rounded to 0.1; show this number so the label always matches it.
  final double roundedValue;
  final BmiCategory category;
}
