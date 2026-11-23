import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/theme/readable_color.dart';
import 'package:fluw/core/widgets/nutrient_target_status.dart';

/// One line of "eaten / target" with a bar, as in the design: coloured dot and label on the left, the amounts and
/// the percentage on the right. A missing total reads "Chưa có dữ liệu" and draws no bar, so it is never mistaken
/// for 0.
class NutrientProgress extends StatelessWidget {
  const NutrientProgress({
    required this.nutrient,
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    required this.kind,
    super.key,
  });

  /// Sets how the numbers are shown and compared.
  final Nutrient nutrient;
  final String label;
  final double? value;
  final double? target;
  final String unit;
  final Color color;
  final NutrientTargetKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = this.value;
    final target = this.target;
    final status = NutrientTargetStatus.of(nutrient: nutrient, value: value, target: target, kind: kind);
    final percent = status.percent;
    final barColor = status.isOver ? status.overColor(scheme) : color;
    final muted = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: 2,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: Text(label, style: theme.textTheme.bodyMedium)),
              ],
            ),
            Wrap(
              spacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      if (value == null)
                        TextSpan(text: 'Chưa có dữ liệu', style: muted)
                      else
                        TextSpan(text: '${formatShownAmount(nutrient, value)} $unit', style: theme.textTheme.value),
                      if (target != null)
                        TextSpan(
                          text: ' / ${status.targetWord} ${formatShownAmount(nutrient, target)} $unit',
                          style: muted,
                        ),
                    ],
                  ),
                ),
                if (percent != null)
                  Text(
                    '($percent%)',
                    style: theme.textTheme.value?.copyWith(color: readableOn(barColor, scheme.surfaceContainerLowest)),
                  ),
              ],
            ),
          ],
        ),
        if (percent != null) ...[
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: status.share,
            color: barColor,
            backgroundColor: scheme.surfaceContainerHighest,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: label,
            // Flutter only accepts 0–100%; going over is said by the text below.
            semanticsValue: '${percent.clamp(0, 100)}%',
          ),
        ],
        if (status.overText case final overText?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(overText, style: theme.textTheme.bodySmall?.copyWith(color: status.overColor(scheme))),
          ),
      ],
    );
  }
}
