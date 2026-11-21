/// BMI the protein and water targets stop growing at.
const double referenceBmi = 24.9;

/// The weight protein and water are worked out from: the real weight, capped at [referenceBmi]. The protein ranges
/// come from studies on mostly lean people, and obesity care uses an ideal or adjusted weight instead of the real one.
final class ReferenceWeight {
  factory ReferenceWeight.fromMeasurements({required double weightKg, required double heightCm}) {
    final heightM = heightCm / 100;
    final capKg = referenceBmi * heightM * heightM;
    return weightKg > capKg ? ReferenceWeight._(capKg, isCapped: true) : ReferenceWeight._(weightKg, isCapped: false);
  }

  const ReferenceWeight._(this.kg, {required this.isCapped});

  final double kg;

  /// True when [kg] is the [referenceBmi] weight, not the real one.
  final bool isCapped;
}
