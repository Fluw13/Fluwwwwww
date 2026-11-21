import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/core/widgets/nutrient_progress.dart';
import 'package:fluw/core/widgets/section_card.dart';

/// The day's totals against the profile's targets. Totals only count foods that have the number; when some lack it
/// the card says so, so a partial sum is never read as the whole day. Sodium appears for every adult with targets;
/// saturated fat only with high blood lipids.
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
      if (limits.tracksSodium) Nutrient.sodiumMg,
    ];
    final hasMissing = shown.any((nutrient) => !totals[nutrient].isComplete);
    final note = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget row(Nutrient nutrient) => switch (nutrient) {
      Nutrient.energyKcal => NutrientProgress(
        nutrient: nutrient,
        label: 'Năng lượng',
        value: totals[nutrient].knownSum,
        target: limits.dailyKcal,
        unit: 'kcal',
        color: colors.energy,
        kind: NutrientTargetKind.calorieGoal,
      ),
      Nutrient.proteinG => NutrientProgress(
        nutrient: nutrient,
        label: 'Protein (đạm)',
        value: totals[nutrient].knownSum,
        target: limits.proteinMinG,
        unit: 'g',
        color: colors.protein,
        kind: NutrientTargetKind.minimum,
      ),
      Nutrient.sugarsG => NutrientProgress(
        nutrient: nutrient,
        label: 'Đường tổng',
        value: totals[nutrient].knownSum,
        target: limits.sugarsMaxG,
        unit: 'g',
        color: colors.sugars,
        kind: NutrientTargetKind.suggestion,
      ),
      Nutrient.saturatedFatG => NutrientProgress(
        nutrient: nutrient,
        label: 'Béo bão hòa',
        value: totals[nutrient].knownSum,
        target: limits.saturatedFatMaxG,
        unit: 'g',
        color: colors.fat,
        kind: NutrientTargetKind.limit,
      ),
      Nutrient.sodiumMg => NutrientProgress(
        nutrient: nutrient,
        label: 'Natri',
        value: totals[nutrient].knownSum,
        target: limits.sodiumMaxMg,
        unit: 'mg',
        color: theme.colorScheme.tertiary,
        kind: NutrientTargetKind.limit,
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
