import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// One number with its unit and an optional explanation, e.g. "Protein (đạm) · 126–168 g/ngày".
class TargetTile extends StatelessWidget {
  const TargetTile({
    required this.label,
    required this.value,
    this.unit,
    this.note,
    this.icon,
    this.iconColor,
    super.key,
  });

  final String label;
  final String value;
  final String? unit;
  final String? note;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = this.unit;
    final note = this.note;
    final icon = this.icon;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              if (icon != null) Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              text: value,
              style: theme.textTheme.headlineSmall,
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(note, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
