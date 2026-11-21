import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_spacing.dart';

enum NutrientTargetKind {
  /// Calories: going over is said, as a target rather than a limit.
  calorieGoal,

  /// Protein: the lower end to reach; going over is fine.
  minimum,

  /// Saturated fat, sodium: going over is a warning.
  limit,

  /// Total sugars: the 10% / 5% of energy is a suggestion made from WHO's advice on free sugars, which labels do not
  /// give. Going over is said in the warning colour, never as an exceeded limit.
  suggestion,

  /// Fat and carbohydrates: a plan to follow, shown without warnings.
  target,
}

/// One line of "eaten / target" with a bar. A missing total reads "Chưa có dữ liệu" and draws no bar, so it is never
/// mistaken for 0.
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
    final value = this.value;
    final target = this.target;
    final valueText = value == null ? 'Chưa có dữ liệu' : '${formatShownAmount(nutrient, value)} $unit';
    final targetWord = switch (kind) {
      NutrientTargetKind.calorieGoal || NutrientTargetKind.target => 'mục tiêu',
      NutrientTargetKind.minimum => 'cần ít nhất',
      NutrientTargetKind.limit => 'tối đa',
      NutrientTargetKind.suggestion => 'mức gợi ý',
    };
    final fullText = target == null
        ? valueText
        : '$valueText / $targetWord ${formatShownAmount(nutrient, target)} $unit';
    final percent = value == null || target == null || target <= 0
        ? null
        : percentAsShown(nutrient, amount: value, target: target);
    final warnsOver = kind != NutrientTargetKind.minimum && kind != NutrientTargetKind.target;
    final isOver = percent != null && warnsOver && isOverAsShown(nutrient, amount: value!, target: target!);
    final overColor = kind == NutrientTargetKind.suggestion ? theme.colorScheme.tertiary : theme.colorScheme.error;

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
            color: isOver ? overColor : color,
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
            child: Text(switch (kind) {
              NutrientTargetKind.calorieGoal => 'Vượt mục tiêu calo cả ngày.',
              NutrientTargetKind.suggestion => 'Cao hơn mức gợi ý cả ngày.',
              _ => 'Vượt giới hạn cả ngày.',
            }, style: theme.textTheme.bodySmall?.copyWith(color: overColor)),
          ),
      ],
    );
  }
}
