import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_spacing.dart';

enum NutrientTargetKind {
  /// Calories: going over is said, as a target rather than a limit.
  calorieGoal,

  /// Protein: the lower end to reach; going over is fine.
  minimum,

  /// Sugar, saturated fat, sodium: going over is a warning.
  limit,

  /// Fat and carbohydrates: a plan to follow, shown without warnings.
  target,
}

/// One line of "eaten / target" with a bar. A missing total reads "Chưa có dữ liệu" and draws no bar, so it is never
/// mistaken for 0.
class NutrientProgress extends StatelessWidget {
  const NutrientProgress({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    required this.kind,
    this.whole = false,
    super.key,
  });

  final String label;
  final double? value;
  final double? target;
  final String unit;
  final Color color;
  final NutrientTargetKind kind;
  final bool whole;

  String _format(double number) => whole ? formatWhole(number) : formatDecimal(number);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = this.value;
    final target = this.target;
    final valueText = value == null ? 'Chưa có dữ liệu' : '${_format(value)} $unit';
    final targetWord = switch (kind) {
      NutrientTargetKind.calorieGoal || NutrientTargetKind.target => 'mục tiêu',
      NutrientTargetKind.minimum => 'cần ít nhất',
      NutrientTargetKind.limit => 'tối đa',
    };
    final fullText = target == null ? valueText : '$valueText / $targetWord ${_format(target)} $unit';
    // Judged on the rounded percentage, like the detail screen, so "100%" never comes with "over".
    final percent = value == null || target == null || target <= 0 ? null : (value / target * 100).round();
    final warnsOver = kind == NutrientTargetKind.calorieGoal || kind == NutrientTargetKind.limit;
    final isOver = percent != null && percent > 100 && warnsOver;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.sm,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            Text(fullText, style: theme.textTheme.bodyMedium),
          ],
        ),
        if (percent != null) ...[
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: (value! / target!).clamp(0, 1).toDouble(),
            color: isOver ? theme.colorScheme.error : color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: label,
            // Flutter only accepts 0–100%; going over is said by the text below.
            semanticsValue: '${percent.clamp(0, 100)}%',
          ),
        ],
        if (isOver)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              kind == NutrientTargetKind.calorieGoal ? 'Vượt mục tiêu calo cả ngày.' : 'Vượt giới hạn cả ngày.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
