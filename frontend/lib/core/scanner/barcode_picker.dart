final RegExp _gtinPattern = RegExp(r'^(\d{8}|\d{12,14})$');

/// The first value that looks like a product barcode (GTIN-8, -12, -13 or -14).
/// Anything else a camera may read (URLs, text) is ignored.
String? firstProductBarcode(Iterable<String?> rawValues) {
  for (final String? raw in rawValues) {
    final String? value = raw?.trim();
    if (value != null && _gtinPattern.hasMatch(value)) return value;
  }
  return null;
}
