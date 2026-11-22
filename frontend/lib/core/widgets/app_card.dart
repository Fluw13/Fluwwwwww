import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// The design's card: rounded, white in the light theme, with a faint shadow (y 1, blur 2, black 5%). The card is its
/// own Material, so ink from buttons inside stays visible on it.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.color,
    this.radius = AppRadius.card,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.elevated = true,
    super.key,
  });

  final Widget child;

  /// Defaults to the card colour of the theme.
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// False for a tinted block that sits flat on the page, like an empty meal slot.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: elevated
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 1), blurRadius: 2)]
            : null,
      ),
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
