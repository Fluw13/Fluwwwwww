import 'package:flutter/widgets.dart';

import '../../data/api/fluw_api_exception.dart';
import 'error_retry_view.dart';

/// Error state for a failed API call: the server's message, a retry button
/// only when retrying can help, locked while the server asks to wait.
class ApiErrorView extends StatelessWidget {
  const ApiErrorView({super.key, required this.error, required this.onRetry});

  static const String unexpectedMessage =
      'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Object error = this.error;
    if (error is! FluwApiException) {
      return ErrorRetryView(message: unexpectedMessage, onRetry: onRetry);
    }
    return ErrorRetryView(
      message: error.message,
      onRetry: error.canRetry ? onRetry : null,
      retryAfter: error.retryAfter,
    );
  }
}
