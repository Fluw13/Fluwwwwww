import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';

/// One number with its unit and an optional explanation, e.g. "Protein (đạm) · 112–168 g/ngày", on a tinted block.
class TargetTile extends StatelessWidget {
  const TargetTile({
    required this.label,
    required this.value,
    this.unit,
    this.note,
    this.icon,
    this.iconColor,
    this.background,
    this.foreground,
    this.isLarge = false,
    super.key,
  });

  final String label;
  final String value;
  final String? unit;
  final String? note;
  final IconData? icon;
  final Color? iconColor;

  /// Defaults to the low surface container; [foreground] is the text colour on it.
  final Color? background;
  final Color? foreground;

  /// The headline number of a group, e.g. the calorie target.
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unit = this.unit;
    final note = this.note;
    final icon = this.icon;
    final foreground = this.foreground;
    final secondary = foreground ?? colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: background ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.inner),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: iconColor ?? colors.primary),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Expanded(
                child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: secondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              text: value,
              style: (isLarge ? theme.textTheme.headlineMedium : theme.textTheme.numberMedium)?.copyWith(
                color: foreground,
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.bodySmall?.copyWith(color: secondary),
                  ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondary,
                fontWeight: foreground == null ? null : FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
