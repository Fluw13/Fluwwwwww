import 'dart:async';

import 'package:flutter/material.dart';

/// "Thử lại" button. With [retryAfter] it stays disabled and counts down the
/// seconds the server asked to wait; it never retries by itself.
class RetryCountdownButton extends StatefulWidget {
  const RetryCountdownButton({
    super.key,
    required this.onRetry,
    this.retryAfter,
    this.tonal = false,
  });

  final VoidCallback onRetry;
  final Duration? retryAfter;

  /// A lighter button for use inside a card.
  final bool tonal;

  @override
  State<RetryCountdownButton> createState() => _RetryCountdownButtonState();
}

class _RetryCountdownButtonState extends State<RetryCountdownButton> {
  Timer? _ticker;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void didUpdateWidget(RetryCountdownButton oldWidget) {
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
    final bool coolingDown = _secondsLeft > 0;
    final VoidCallback? onPressed = coolingDown ? null : widget.onRetry;
    final Widget icon = Icon(coolingDown ? Icons.hourglass_top : Icons.refresh);
    final Widget label = Text(
      coolingDown ? 'Thử lại sau $_secondsLeft giây' : 'Thử lại',
    );

    return widget.tonal
        ? FilledButton.tonalIcon(onPressed: onPressed, icon: icon, label: label)
        : FilledButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}
