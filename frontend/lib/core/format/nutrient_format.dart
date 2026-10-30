/// Vietnamese number style: "," for decimals, "." for thousands, at most one
/// decimal and no trailing ",0". Values below zero are treated as zero.
class NutrientFormat {
  const NutrientFormat._();

  static const String missing = '—';

  static String grams(double? value) {
    if (value == null) return missing;
    final String fixed = _nonNegative(value).toStringAsFixed(1);
    final List<String> parts = fixed.split('.');
    final String integer = _groupThousands(parts[0]);
    return parts[1] == '0' ? integer : '$integer,${parts[1]}';
  }

  static String kcal(double? value) {
    if (value == null) return missing;
    return _groupThousands(_nonNegative(value).round().toString());
  }

  static double _nonNegative(double value) => value < 0 ? 0 : value;

  static String _groupThousands(String digits) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
