import 'vietnamese_number.dart';

/// Nutrient values in Vietnamese number style. Precision follows the backend,
/// which rounds before comparing with score thresholds (kJ to 0.1, grams to
/// 0.01), so a value shown here never contradicts its threshold range.
/// Values below zero are treated as zero.
class NutrientFormat {
  const NutrientFormat._();

  static const String missing = '—';

  static String grams(double? value) => _format(value, 2);

  static String kilojoules(double? value) => _format(value, 1);

  static String kcal(double? value) => _format(value, 0);

  static String _format(double? value, int maxFractionDigits) {
    if (value == null) return missing;
    return formatVietnameseNumber(
      value < 0 ? 0 : value,
      maxFractionDigits: maxFractionDigits,
    );
  }
}
