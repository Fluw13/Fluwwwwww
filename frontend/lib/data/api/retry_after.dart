import 'http_date.dart';

/// Upper bound so a wrong header cannot keep the retry button locked for hours.
const Duration maxRetryAfter = Duration(minutes: 10);

/// Reads a `Retry-After` header given either as delay-seconds or as an
/// HTTP-date. Returns null when the header is missing or unreadable.
Duration? parseRetryAfter(String? header, {required DateTime now}) {
  if (header == null) return null;
  final String value = header.trim();
  if (value.isEmpty) return null;

  if (RegExp(r'^\d+$').hasMatch(value)) {
    final int? seconds = int.tryParse(value);
    return _clamp(seconds == null ? maxRetryAfter : Duration(seconds: seconds));
  }

  final DateTime? date = parseHttpDate(value);
  if (date == null) return null;
  return _clamp(date.difference(now.toUtc()));
}

Duration _clamp(Duration value) {
  if (value.isNegative) return Duration.zero;
  return value > maxRetryAfter ? maxRetryAfter : value;
}
