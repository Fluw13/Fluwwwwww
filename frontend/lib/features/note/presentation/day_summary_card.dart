import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/core/widgets/section_card.dart';

enum _TargetKind { calorieGoal, minimum, limit }

/// The day's totals against the profile's targets. Totals only count foods that have the number; when some lack it
/// the card says so, so a partial sum is never read as the whole day. Sodium and saturated fat appear only for the
/// conditions that track them.
class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({required this.totals, required this.entryCount, required this.limits, super.key});

  final NutrientTotals totals;
  final int entryCount;
  final PersonalLimits limits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NutrientColors>()!;
    final shown = [
      Nutrient.energyKcal,
      Nutrient.proteinG,
      Nutrient.sugarsG,
      if (limits.watchesSaturatedFat) Nutrient.saturatedFatG,
      if (limits.watchesSodium) Nutrient.sodiumMg,
    ];
    final hasMissing = shown.any((nutrient) => totals[nutrient].missingCount > 0);
    final note = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget row(Nutrient nutrient) => switch (nutrient) {
      Nutrient.energyKcal => _Progress(
        label: 'Năng lượng',
        value: totals[nutrient].knownSum,
        target: limits.dailyKcal,
        unit: 'kcal',
        color: colors.energy,
        kind: _TargetKind.calorieGoal,
        whole: true,
      ),
      Nutrient.proteinG => _Progress(
        label: 'Protein (đạm)',
        value: totals[nutrient].knownSum,
        target: limits.proteinMinG,
        unit: 'g',
        color: colors.protein,
        kind: _TargetKind.minimum,
      ),
      Nutrient.sugarsG => _Progress(
        label: 'Đường tổng',
        value: totals[nutrient].knownSum,
        target: limits.sugarsMaxG,
        unit: 'g',
        color: colors.sugars,
        kind: _TargetKind.limit,
      ),
      Nutrient.saturatedFatG => _Progress(
        label: 'Béo bão hòa',
        value: totals[nutrient].knownSum,
        target: limits.saturatedFatMaxG,
        unit: 'g',
        color: colors.fat,
        kind: _TargetKind.limit,
      ),
      Nutrient.sodiumMg => _Progress(
        label: 'Natri',
        value: totals[nutrient].knownSum,
        target: limits.sodiumMaxMg,
        unit: 'mg',
        color: theme.colorScheme.tertiary,
        kind: _TargetKind.limit,
        whole: true,
      ),
      _ => const SizedBox.shrink(),
    };

    return SectionCard(
      title: 'Tổng trong ngày',
      children: [
        for (final (index, nutrient) in shown.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          row(nutrient),
        ],
        if (entryCount > 0 && hasMissing) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Có món thiếu số liệu nên tổng có thể thấp hơn thực tế.', style: note),
        ],
        if (limits.profileStatus != ProfileStatus.loaded) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            limits.profileStatus == ProfileStatus.unreadable
                ? 'Không đọc được hồ sơ nên chưa so được với chỉ tiêu.'
                : 'Thiết lập hồ sơ để so với chỉ tiêu mỗi ngày.',
            style: note,
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
    required this.kind,
    this.whole = false,
  });

  final String label;
  final double? value;
  final double? target;
  final String unit;
  final Color color;
  final _TargetKind kind;
  final bool whole;

  String _format(double number) => whole ? formatWhole(number) : formatDecimal(number);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = this.value;
    final target = this.target;
    final valueText = value == null ? 'Chưa có dữ liệu' : '${_format(value)} $unit';
    final targetWord = switch (kind) {
      _TargetKind.calorieGoal => 'mục tiêu',
      _TargetKind.minimum => 'cần ít nhất',
      _TargetKind.limit => 'tối đa',
    };
    final fullText = target == null ? valueText : '$valueText / $targetWord ${_format(target)} $unit';
    // Judged on the rounded percentage, like the detail screen, so "100%" never comes with "over".
    final percent = value == null || target == null || target <= 0 ? null : (value / target * 100).round();
    final isOver = percent != null && percent > 100 && kind != _TargetKind.minimum;

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
              kind == _TargetKind.calorieGoal ? 'Vượt mục tiêu calo cả ngày.' : 'Vượt giới hạn cả ngày.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
