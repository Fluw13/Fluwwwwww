import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/theme/readable_color.dart';
import 'package:fluw/core/widgets/nutrient_target_status.dart';

/// A tinted box with one nutrient's total against its target, like the design's protein and sugar boxes. Same rules
/// as `NutrientProgress`: the target word stays ("cần ít nhất", "mức gợi ý"), a missing total is never 0.
class NutrientStatBox extends StatelessWidget {
  const NutrientStatBox({
    required this.nutrient,
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    required this.kind,
    super.key,
  });

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
    final background = scheme.surfaceContainerLow;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: readableOn(barColor, background));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.xs,
            children: [
              Text(label.toUpperCase(), semanticsLabel: label, style: labelStyle),
              if (percent != null) Text('$percent%', style: labelStyle),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              children: [
                if (value == null)
                  TextSpan(text: 'Chưa có dữ liệu', style: theme.textTheme.bodyMedium)
                else
                  TextSpan(text: formatShownAmount(nutrient, value), style: theme.textTheme.numberMedium),
                TextSpan(
                  text: target == null
                      ? (value == null ? '' : ' $unit')
                      : ' / ${status.targetWord} ${formatShownAmount(nutrient, target)} $unit',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (status.share case final share?) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: share,
              color: barColor,
              backgroundColor: scheme.surfaceContainerHighest,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              semanticsLabel: label,
              semanticsValue: '${percent!.clamp(0, 100)}%',
            ),
          ],
          if (status.overText case final overText?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(overText, style: theme.textTheme.bodySmall?.copyWith(color: status.overColor(scheme))),
            ),
        ],
      ),
    );
  }
}
