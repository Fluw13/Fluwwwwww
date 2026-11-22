import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/core/widgets/nutrient_progress.dart';
import 'package:fluw/core/widgets/nutrient_target_status.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/note/presentation/nutrient_stat_box.dart';

/// The day's totals against the profile's targets. Totals only count foods that have the number; when some lack it
/// the card says so, so a partial sum is never read as the whole day. Sodium appears for every adult with targets;
/// saturated fat only with high blood lipids.
class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({
    required this.title,
    required this.totals,
    required this.entryCount,
    required this.limits,
    super.key,
  });

  final String title;
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
    final note = theme.textTheme.bodySmall;
    final protein = NutrientStatBox(
      nutrient: Nutrient.proteinG,
      label: 'Protein (đạm)',
      value: totals[Nutrient.proteinG].knownSum,
      target: limits.proteinMinG,
      unit: 'g',
      color: colors.protein,
      kind: NutrientTargetKind.minimum,
    );
    final sugars = NutrientStatBox(
      nutrient: Nutrient.sugarsG,
      label: 'Đường tổng',
      value: totals[Nutrient.sugarsG].knownSum,
      target: limits.sugarsMaxG,
      unit: 'g',
      color: colors.sugars,
      kind: NutrientTargetKind.suggestion,
    );

    return SectionCard(
      title: title,
      subtitle: 'Tổng các món đã ghi',
      icon: Icons.local_fire_department_outlined,
      children: [
        _EnergyTotal(total: totals[Nutrient.energyKcal], target: limits.dailyKcal, color: colors.energy),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            // Side by side as in the design; stacked when a narrow screen or large text leaves no room.
            if (constraints.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) > 1.3) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  protein,
                  const SizedBox(height: AppSpacing.sm),
                  sugars,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: protein),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: sugars),
                ],
              ),
            );
          },
        ),
        if (limits.watchesSaturatedFat) ...[
          const SizedBox(height: AppSpacing.md),
          NutrientProgress(
            nutrient: Nutrient.saturatedFatG,
            label: 'Béo bão hòa',
            value: totals[Nutrient.saturatedFatG].knownSum,
            target: limits.saturatedFatMaxG,
            unit: 'g',
            color: colors.fat,
            kind: NutrientTargetKind.limit,
          ),
        ],
        if (limits.tracksSodium) ...[
          const SizedBox(height: AppSpacing.md),
          NutrientProgress(
            nutrient: Nutrient.sodiumMg,
            label: 'Natri',
            value: totals[Nutrient.sodiumMg].knownSum,
            target: limits.sodiumMaxMg,
            unit: 'mg',
            color: theme.colorScheme.tertiary,
            kind: NutrientTargetKind.limit,
          ),
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

/// The large "eaten / target kcal" line with what is left, and its bar.
class _EnergyTotal extends StatelessWidget {
  const _EnergyTotal({required this.total, required this.target, required this.color});

  final NutrientTotal total;
  final double? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kcal = total.knownSum;
    final target = this.target;
    const nutrient = Nutrient.energyKcal;
    final status = NutrientTargetStatus.of(
      nutrient: nutrient,
      value: kcal,
      target: target,
      kind: NutrientTargetKind.calorieGoal,
    );
    final muted = theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant);
    final String? balance;
    if (kcal == null || target == null) {
      balance = null;
    } else if (status.isOver) {
      final over = formatShownAmount(nutrient, shownDifference(nutrient, amount: kcal, target: target));
      balance = total.isComplete ? 'Vượt: $over kcal' : 'Vượt ít nhất: $over kcal';
    } else {
      final left = formatShownAmount(nutrient, shownDifference(nutrient, amount: target, target: kcal));
      balance = total.isComplete ? 'Còn lại: $left kcal' : 'Còn lại tối đa: $left kcal';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AppSpacing.sm,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  if (kcal == null)
                    TextSpan(text: 'Năng lượng: chưa có dữ liệu', style: theme.textTheme.titleMedium)
                  else
                    TextSpan(text: formatShownAmount(nutrient, kcal), style: theme.textTheme.headlineMedium),
                  if (target != null)
                    TextSpan(text: ' / ${formatShownAmount(nutrient, target)} kcal', style: muted)
                  else if (kcal != null)
                    TextSpan(text: ' kcal', style: muted),
                ],
              ),
            ),
            if (balance != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  balance,
                  style: theme.textTheme.value?.copyWith(
                    color: status.isOver ? status.overColor(scheme) : scheme.primary,
                  ),
                ),
              ),
          ],
        ),
        if (status.share case final share?) ...[
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: share,
            color: status.isOver ? status.overColor(scheme) : color,
            backgroundColor: scheme.surfaceContainerHighest,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: 'Năng lượng',
            semanticsValue: '${status.percent!.clamp(0, 100)}%',
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
