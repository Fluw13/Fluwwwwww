import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

/// Tells the user which screen is opening and what is being loaded.
/// [slowHint] appears only if loading takes longer than [slowAfter].
class LoadingStatusBanner extends StatefulWidget {
  const LoadingStatusBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.slowHint,
    this.slowAfter = const Duration(seconds: 8),
  });

  final String title;
  final String? subtitle;
  final String? slowHint;
  final Duration slowAfter;

  @override
  State<LoadingStatusBanner> createState() => _LoadingStatusBannerState();
}

class _LoadingStatusBannerState extends State<LoadingStatusBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    lowerBound: 0.35,
  );

  Timer? _slowTimer;
  bool _isSlow = false;

  @override
  void initState() {
    super.initState();
    _scheduleSlowHint();
  }

  @override
  void didUpdateWidget(LoadingStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slowHint != widget.slowHint || oldWidget.slowAfter != widget.slowAfter) {
      _isSlow = false;
      _scheduleSlowHint();
    }
  }

  void _scheduleSlowHint() {
    _slowTimer?.cancel();
    _slowTimer = null;
    if (widget.slowHint == null) return;

    _slowTimer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _isSlow = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? subtitle = widget.subtitle;
    final String? slowHint = widget.slowHint;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: FadeTransition(
                opacity: _pulse,
                child: Icon(Icons.auto_awesome, size: 18, color: palette.accentText),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                  if (_isSlow && slowHint != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(slowHint, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
