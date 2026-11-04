import 'api_error_kind.dart';

class FluwApiException implements Exception {
  FluwApiException({
    required this.kind,
    String? message,
    this.code,
    this.statusCode,
    this.retryAfter,
  }) : message = message ?? kind.defaultMessage;

  final ApiErrorKind kind;

  /// Vietnamese text safe to show to the user.
  final String message;

  /// Raw `code` from the server body, kept even when [kind] does not know it.
  final String? code;
  final int? statusCode;

  /// How long the server asked the client to wait before trying again.
  final Duration? retryAfter;

  bool get canRetry => kind.canRetry;

  // The message can echo a barcode or search text, so it stays out of logs.
  @override
  String toString() =>
      'FluwApiException(${kind.name}, status: $statusCode, code: $code)';
}
