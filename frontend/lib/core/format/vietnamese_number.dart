/// Vietnamese number style: "," for decimals, "." for thousands, no trailing
/// zeros ("3,5", "1.340", "0,01"). Negative numbers use the minus sign "−".
String formatVietnameseNumber(num value, {int maxFractionDigits = 2}) {
  final String fixed = value.abs().toStringAsFixed(maxFractionDigits);
  final List<String> parts = fixed.split('.');
  final String integer = _groupThousands(parts.first);
  final String fraction = parts.length > 1
      ? parts[1].replaceFirst(RegExp(r'0+$'), '')
      : '';
  final String unsigned = fraction.isEmpty ? integer : '$integer,$fraction';
  final bool isZero = RegExp(r'^[0.]+$').hasMatch(fixed);
  return value < 0 && !isZero ? '−$unsigned' : unsigned;
}

String _groupThousands(String digits) {
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
