import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

/// Full-area error state with a single retry action. Scrolls when the screen
/// is short (landscape, large text) and announces the message to screen readers.
///
/// With [retryAfter] the button stays disabled and counts down; it never
/// retries by itself. Without [onRetry] there is no button.
class ErrorRetryView extends StatefulWidget {
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
  State<ErrorRetryView> createState() => _ErrorRetryViewState();
}

class _ErrorRetryViewState extends State<ErrorRetryView> {
  Timer? _ticker;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void didUpdateWidget(ErrorRetryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.retryAfter != widget.retryAfter) _startCooldown();
  }

  void _startCooldown() {
    _ticker?.cancel();
    final Duration wait = widget.retryAfter ?? Duration.zero;
    _secondsLeft = (wait.inMilliseconds / 1000).ceil();
    if (_secondsLeft <= 0) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final VoidCallback? onRetry = widget.onRetry;
    final bool coolingDown = _secondsLeft > 0;

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
                      widget.message,
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
                    FilledButton.icon(
                      onPressed: coolingDown ? null : onRetry,
                      icon: Icon(
                        coolingDown ? Icons.hourglass_top : Icons.refresh,
                      ),
                      label: Text(
                        coolingDown
                            ? 'Thử lại sau $_secondsLeft giây'
                            : 'Thử lại',
                      ),
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
