/// Null-safe readers for decoded JSON. Each returns null (or an empty list)
/// when the value is missing or has an unexpected type, so one odd field from
/// the server never breaks a whole screen.
library;

Map<String, dynamic>? readMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

/// Trims the string and treats blank text as missing.
String? readString(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? readDouble(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;

int? readInt(Object? value) {
  if (value is int) return value;
  if (value is! double || !value.isFinite) return null;
  return value == value.roundToDouble() ? value.toInt() : null;
}

bool? readBool(Object? value) => value is bool ? value : null;

DateTime? readDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Reads every element with [readItem] and drops the ones it rejects.
List<T> readList<T extends Object>(
  Object? value,
  T? Function(Object? item) readItem,
) {
  if (value is! List) return const [];
  return List.unmodifiable(value.map(readItem).whereType<T>());
}

List<String> readStringList(Object? value) =>
    readList<String>(value, readString);

/// For fields the contract guarantees; a missing one means the response
/// cannot be trusted at all.
String requireString(Map<String, dynamic> json, String key) {
  final String? value = readString(json[key]);
  if (value == null) throw FormatException('Thiếu trường bắt buộc "$key"');
  return value;
}

Map<String, dynamic> requireMap(Map<String, dynamic> json, String key) {
  final Map<String, dynamic>? value = readMap(json[key]);
  if (value == null) throw FormatException('Thiếu trường bắt buộc "$key"');
  return value;
}
