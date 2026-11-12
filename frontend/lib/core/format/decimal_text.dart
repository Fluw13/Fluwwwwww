/// Accepts both "58,5" (Vietnamese keyboards) and "58.5" with up to [maxFractionDigits] decimals; returns `null` for
/// anything else, including negative numbers.
double? parseDecimal(String text, {int maxFractionDigits = 2}) {
  final normalized = text.trim().replaceAll(',', '.');
  if (!RegExp('^\\d+(\\.\\d{1,$maxFractionDigits})?\$').hasMatch(normalized)) {
    return null;
  }
  return double.parse(normalized);
}

/// Shows at most [maxFractionDigits] decimals and drops trailing zeros, like the design: 58.5, 165, 0.25.
String formatDecimal(double value, {int maxFractionDigits = 1}) {
  final fixed = value.toStringAsFixed(maxFractionDigits);
  if (!fixed.contains('.')) {
    return fixed;
  }
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Rounds to a whole number and groups thousands with commas, like the design: 1,850.
String formatWhole(double value) {
  final digits = value.round().abs().toString();
  final grouped = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
  return value.round() < 0 ? '-$grouped' : grouped;
}
