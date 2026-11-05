import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import 'retry_countdown_button.dart';

/// Full-area error state with a single retry action. Scrolls when the screen
/// is short (landscape, large text) and announces the message to screen readers.
///
/// With [retryAfter] the button stays disabled and counts down; it never
/// retries by itself. Without [onRetry] there is no button.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryAfter,
  });

  final String message;
  final VoidCallback? onRetry;
  final Duration? retryAfter;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final VoidCallback? onRetry = this.onRetry;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: palette.scorePoor.container,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 32,
                      color: palette.scorePoor.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    RetryCountdownButton(
                      onRetry: onRetry,
                      retryAfter: retryAfter,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
