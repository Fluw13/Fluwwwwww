import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/core/widgets/nutrient_progress.dart';
import 'package:fluw/core/widgets/nutrient_target_status.dart';
import 'package:fluw/core/widgets/section_card.dart';

/// The design's calorie ring and nutrient bars for today. Totals only count foods that have each number; when some
/// lack it, what is left is an upper bound and is said so.
class TodayNutritionCard extends StatelessWidget {
  const TodayNutritionCard({required this.totals, required this.entryCount, required this.limits, super.key});

  final NutrientTotals totals;
  final int entryCount;
  final PersonalLimits limits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NutrientColors>()!;
    final muted = theme.textTheme.bodySmall;
    final kcalTotal = totals[Nutrient.energyKcal];
    final kcal = kcalTotal.knownSum;
    final target = limits.dailyKcal;
    final shown = [
      Nutrient.energyKcal,
      Nutrient.proteinG,
      Nutrient.sugarsG,
      Nutrient.carbohydratesG,
      Nutrient.fatG,
      if (limits.watchesSaturatedFat) Nutrient.saturatedFatG,
      if (limits.tracksSodium) Nutrient.sodiumMg,
    ];
    final hasMissing = entryCount > 0 && shown.any((nutrient) => !totals[nutrient].isComplete);
    final carbsUnavailable = limits.targetsKind == TargetsKind.adult && limits.carbohydratesTargetG == null;
    const rowGap = SizedBox(height: AppSpacing.sm + AppSpacing.xs);

    return SectionCard(
      title: 'Dinh dưỡng hôm nay',
      icon: Icons.data_usage,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.inner),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ring = _CalorieRing(
                kcal: kcal,
                isComplete: kcalTotal.isComplete,
                target: target,
                color: colors.energy,
              );
              final summary = _CalorieSummary(
                kcal: kcal,
                isComplete: kcalTotal.isComplete,
                target: target,
                noTargetReason: _noTargetReason(),
              );
              // Side by side as in the design; stacked when a narrow screen or large text leaves no room.
              if (constraints.maxWidth < 270 || MediaQuery.textScalerOf(context).scale(1) > 1.5) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: ring),
                    const SizedBox(height: AppSpacing.md),
                    summary,
                  ],
                );
              }
              return Row(
                children: [
                  ring,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: summary),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        NutrientProgress(
          nutrient: Nutrient.proteinG,
          label: 'Protein (đạm)',
          value: totals[Nutrient.proteinG].knownSum,
          target: limits.proteinMinG,
          unit: 'g',
          color: colors.protein,
          kind: NutrientTargetKind.minimum,
        ),
        rowGap,
        NutrientProgress(
          nutrient: Nutrient.sugarsG,
          label: 'Đường tổng',
          value: totals[Nutrient.sugarsG].knownSum,
          target: limits.sugarsMaxG,
          unit: 'g',
          color: colors.sugars,
          kind: NutrientTargetKind.suggestion,
        ),
        rowGap,
        NutrientProgress(
          nutrient: Nutrient.carbohydratesG,
          label: 'Carb (bột đường)',
          value: totals[Nutrient.carbohydratesG].knownSum,
          target: limits.carbohydratesTargetG,
          unit: 'g',
          color: colors.carbohydrates,
          kind: NutrientTargetKind.target,
        ),
        if (carbsUnavailable) Text('Mục tiêu carb: chưa tính được với hồ sơ này.', style: muted),
        rowGap,
        NutrientProgress(
          nutrient: Nutrient.fatG,
          label: 'Chất béo',
          value: totals[Nutrient.fatG].knownSum,
          target: limits.fatTargetG,
          unit: 'g',
          color: colors.fat,
          kind: NutrientTargetKind.target,
        ),
        if (limits.watchesSaturatedFat) ...[
          rowGap,
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
          rowGap,
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
        if (hasMissing) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Có món thiếu số liệu nên tổng có thể thấp hơn thực tế.', style: muted),
        ],
      ],
    );
  }

  String _noTargetReason() => switch ((limits.profileStatus, limits.targetsKind)) {
    (ProfileStatus.loaded, TargetsKind.belowMinimumAge) => 'Fluw dành cho người từ 18 tuổi.',
    (ProfileStatus.loaded, TargetsKind.pregnancyOrBreastfeeding) => 'Mang thai hoặc cho con bú: Fluw không tính calo.',
    (ProfileStatus.loaded, _) => 'Hồ sơ chưa đủ để tính mục tiêu calo.',
    (ProfileStatus.unreadable, _) => 'Không đọc được hồ sơ.',
    _ => 'Thiết lập hồ sơ để có mục tiêu calo.',
  };
}

/// What is left of today's target (or how far over it), a small bar and the plan, beside the ring.
class _CalorieSummary extends StatelessWidget {
  const _CalorieSummary({
    required this.kcal,
    required this.isComplete,
    required this.target,
    required this.noTargetReason,
  });

  final double? kcal;
  final bool isComplete;
  final double? target;
  final String noTargetReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final kcal = this.kcal;
    final target = this.target;

    if (target == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chưa có mục tiêu calo', style: theme.textTheme.titleMedium),
          Text(noTargetReason, style: theme.textTheme.bodySmall),
        ],
      );
    }
    final plan = Text('Kế hoạch: ${formatWhole(target)} kcal (ước tính)', style: label);
    if (kcal == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chưa có dữ liệu calo của các món hôm nay', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          plan,
        ],
      );
    }

    final status = NutrientTargetStatus.of(
      nutrient: Nutrient.energyKcal,
      value: kcal,
      target: target,
      kind: NutrientTargetKind.calorieGoal,
    );
    final amountColor = status.isOver ? status.overColor(scheme) : scheme.primary;
    final (heading, amount) = status.isOver
        ? (
            isComplete ? 'Đã vượt' : 'Đã vượt ít nhất',
            shownDifference(Nutrient.energyKcal, amount: kcal, target: target),
          )
        : (
            isComplete ? 'Còn lại hôm nay' : 'Còn lại tối đa',
            shownDifference(Nutrient.energyKcal, amount: target, target: kcal),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(heading, style: label),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: formatWhole(amount),
                style: theme.textTheme.numberMedium?.copyWith(color: amountColor),
              ),
              TextSpan(
                text: ' kcal',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // The ring already tells screen readers the same numbers.
            Expanded(
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: status.share,
                  color: status.isOver ? amountColor : theme.extension<NutrientColors>()!.energy,
                  backgroundColor: scheme.surfaceContainerHighest,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('${status.percent}%', style: label?.copyWith(color: scheme.onSurface)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        plan,
      ],
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.kcal, required this.isComplete, required this.target, required this.color});

  final double? kcal;
  final bool isComplete;
  final double? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kcal = this.kcal;
    final target = this.target;
    final eatenText = kcal == null ? 'Chưa có' : formatWhole(kcal);
    final spoken = switch (kcal) {
      null => 'chưa có dữ liệu calo',
      _ => '${isComplete ? '' : 'ít nhất '}${formatWhole(kcal)} kcal',
    };

    return Semantics(
      label: 'Năng lượng đã nạp hôm nay',
      value: target == null ? spoken : '$spoken, mục tiêu ${formatWhole(target)} kcal',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 104,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: target == null || target <= 0 ? 0 : ((kcal ?? 0) / target).clamp(0, 1).toDouble(),
              strokeWidth: 10,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              strokeCap: StrokeCap.round,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(eatenText, style: theme.textTheme.headlineMedium),
                      Text(
                        'KCAL ĐÃ NẠP',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
