import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// A small icon, the title and an optional trailing link or pill, as at the top of every section in the design. The
/// trailing widget moves under the title when they do not fit on one line.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.icon, this.iconColor, this.subtitle, this.trailing, super.key});

  final String title;
  final IconData? icon;

  /// Defaults to the primary colour.
  final Color? iconColor;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = this.icon;
    final subtitle = this.subtitle;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        Semantics(
          header: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: iconColor ?? theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    if (subtitle != null) Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
