/// Only digits, and as many as a GTIN has. Lets the screen tell a wrong length from a typo in one digit.
bool hasGtinLength(String code) => RegExp(r'^\d+$').hasMatch(code) && const {8, 12, 13, 14}.contains(code.length);

/// A product barcode (GTIN-8, -12, -13 or -14) with a valid check digit, the same rule the backend applies before it
/// asks Open Food Facts. Catches typos in a code typed by hand before any request is made.
bool isValidGtin(String code) {
  if (!hasGtinLength(code)) {
    return false;
  }
  final digits = [for (final rune in code.runes) rune - 0x30];
  final check = digits.removeLast();
  var sum = 0;
  for (var index = 0; index < digits.length; index++) {
    // Weights alternate 3, 1, 3… starting from the digit next to the check digit.
    sum += digits[index] * ((digits.length - index).isOdd ? 3 : 1);
  }
  return (10 - sum % 10) % 10 == check;
}

/// True when two barcodes name the same product: a UPC-A label read as EAN-13 gets one more 0 in front.
bool isSameGtin(String first, String second) => _withoutLeadingZeros(first) == _withoutLeadingZeros(second);

String _withoutLeadingZeros(String code) => code.replaceFirst(RegExp('^0+'), '');
