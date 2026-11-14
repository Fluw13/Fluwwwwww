import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/core/widgets/section_card.dart';

/// The day's totals against the profile's targets. Totals only count foods that have the number; how many lack it
/// is said, so a partial sum is never read as the whole day.
class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({required this.totals, required this.entryCount, required this.limits, super.key});

  final NutrientTotals totals;
  final int entryCount;
  final PersonalLimits limits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NutrientColors>()!;
    final missing = {
      for (final nutrient in [Nutrient.energyKcal, Nutrient.proteinG, Nutrient.sugarsG])
        if (totals[nutrient].missingCount > 0) nutrient: totals[nutrient].missingCount,
    };

    return SectionCard(
      title: 'Tổng trong ngày',
      children: [
        _Progress(
          label: 'Năng lượng',
          value: totals[Nutrient.energyKcal].knownSum,
          target: limits.dailyKcal,
          unit: 'kcal',
          color: colors.energy,
          whole: true,
          targetWord: 'mục tiêu',
        ),
        const SizedBox(height: AppSpacing.md),
        _Progress(
          label: 'Protein (đạm)',
          value: totals[Nutrient.proteinG].knownSum,
          target: limits.proteinMinG,
          unit: 'g',
          color: colors.protein,
          targetWord: 'cần ít nhất',
        ),
        const SizedBox(height: AppSpacing.md),
        _Progress(
          label: 'Đường tổng',
          value: totals[Nutrient.sugarsG].knownSum,
          target: limits.sugarsMaxG,
          unit: 'g',
          color: colors.sugars,
          targetWord: 'tối đa',
        ),
        if (entryCount > 0 && missing.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Có món thiếu số liệu nên tổng có thể thấp hơn thực tế.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        if (limits.profileStatus != ProfileStatus.loaded) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            limits.profileStatus == ProfileStatus.unreadable
                ? 'Không đọc được hồ sơ nên chưa so được với chỉ tiêu.'
                : 'Thiết lập hồ sơ để so với chỉ tiêu mỗi ngày.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    required this.targetWord,
    this.whole = false,
  });

  final String label;
  final double? value;
  final double? target;
  final String unit;
  final Color color;
  final String targetWord;
  final bool whole;

  String _format(double number) => whole ? formatWhole(number) : formatDecimal(number);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = this.value;
    final target = this.target;
    final valueText = value == null ? 'Chưa có dữ liệu' : '${_format(value)} $unit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.sm,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            Text(
              target == null ? valueText : '$valueText / $targetWord ${_format(target)} $unit',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        if (target != null && target > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: ((value ?? 0) / target).clamp(0, 1).toDouble(),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ],
    );
  }
}
