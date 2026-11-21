import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/core/widgets/nutrient_progress.dart';
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
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
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
      if (limits.watchesSodium) Nutrient.sodiumMg,
    ];
    final hasMissing = entryCount > 0 && shown.any((nutrient) => !totals[nutrient].isComplete);
    final carbsUnavailable = limits.targetsKind == TargetsKind.adult && limits.carbohydratesTargetG == null;

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._headline(theme, muted, kcal: kcal, isComplete: kcalTotal.isComplete, target: target),
        Text(target == null ? _noTargetReason() : 'Kế hoạch: ${formatWhole(target)} kcal (ước tính)', style: muted),
      ],
    );

    return SectionCard(
      title: 'Dinh dưỡng hôm nay',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final ring = _CalorieRing(
              kcal: kcal,
              isComplete: kcalTotal.isComplete,
              target: target,
              color: colors.energy,
            );
            // Side by side as in the design; stacked when a narrow screen or large text leaves no room.
            if (constraints.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) > 1.5) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: summary),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        NutrientProgress(
          label: 'Protein (đạm)',
          value: totals[Nutrient.proteinG].knownSum,
          target: limits.proteinMinG,
          unit: 'g',
          color: colors.protein,
          kind: NutrientTargetKind.minimum,
        ),
        const SizedBox(height: AppSpacing.sm),
        NutrientProgress(
          label: 'Đường tổng',
          value: totals[Nutrient.sugarsG].knownSum,
          target: limits.sugarsMaxG,
          unit: 'g',
          color: colors.sugars,
          kind: NutrientTargetKind.limit,
        ),
        const SizedBox(height: AppSpacing.sm),
        NutrientProgress(
          label: 'Tinh bột',
          value: totals[Nutrient.carbohydratesG].knownSum,
          target: limits.carbohydratesTargetG,
          unit: 'g',
          color: colors.carbohydrates,
          kind: NutrientTargetKind.target,
        ),
        if (carbsUnavailable) Text('Mục tiêu tinh bột: chưa tính được với hồ sơ này.', style: muted),
        const SizedBox(height: AppSpacing.sm),
        NutrientProgress(
          label: 'Chất béo',
          value: totals[Nutrient.fatG].knownSum,
          target: limits.fatTargetG,
          unit: 'g',
          color: colors.fat,
          kind: NutrientTargetKind.target,
        ),
        if (limits.watchesSaturatedFat) ...[
          const SizedBox(height: AppSpacing.sm),
          NutrientProgress(
            label: 'Béo bão hòa',
            value: totals[Nutrient.saturatedFatG].knownSum,
            target: limits.saturatedFatMaxG,
            unit: 'g',
            color: colors.fat,
            kind: NutrientTargetKind.limit,
          ),
        ],
        if (limits.watchesSodium) ...[
          const SizedBox(height: AppSpacing.sm),
          NutrientProgress(
            label: 'Natri',
            value: totals[Nutrient.sodiumMg].knownSum,
            target: limits.sodiumMaxMg,
            unit: 'mg',
            color: theme.colorScheme.tertiary,
            kind: NutrientTargetKind.limit,
            whole: true,
          ),
        ],
        if (hasMissing) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Có món thiếu số liệu nên tổng có thể thấp hơn thực tế.', style: muted),
        ],
      ],
    );
  }

  List<Widget> _headline(
    ThemeData theme,
    TextStyle? muted, {
    required double? kcal,
    required bool isComplete,
    required double? target,
  }) {
    if (target == null) {
      return [Text('Chưa có mục tiêu calo', style: theme.textTheme.titleMedium)];
    }
    if (kcal == null) {
      return [Text('Chưa có dữ liệu calo của các món hôm nay', style: theme.textTheme.titleMedium)];
    }
    // Compared as shown, so "Đã vượt 0 kcal" never appears.
    if (kcal.round() > target.round()) {
      return [
        Text(isComplete ? 'Đã vượt' : 'Đã vượt ít nhất', style: muted),
        Text('${formatWhole(kcal - target)} kcal', style: theme.textTheme.titleLarge),
      ];
    }
    return [
      Text(isComplete ? 'Còn lại hôm nay' : 'Còn lại tối đa', style: muted),
      Text('${formatWhole(target - kcal)} kcal', style: theme.textTheme.titleLarge),
    ];
  }

  String _noTargetReason() => switch ((limits.profileStatus, limits.targetsKind)) {
    (ProfileStatus.loaded, TargetsKind.belowMinimumAge) => 'Fluw dành cho người từ 18 tuổi.',
    (ProfileStatus.loaded, TargetsKind.pregnancyOrBreastfeeding) => 'Mang thai hoặc cho con bú: Fluw không tính calo.',
    (ProfileStatus.loaded, _) => 'Hồ sơ chưa đủ để tính mục tiêu calo.',
    (ProfileStatus.unreadable, _) => 'Không đọc được hồ sơ.',
    _ => 'Thiết lập hồ sơ để có mục tiêu calo.',
  };
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
        dimension: 132,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: target == null || target <= 0 ? 0 : ((kcal ?? 0) / target).clamp(0, 1).toDouble(),
              strokeWidth: 12,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              strokeCap: StrokeCap.round,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(eatenText, style: theme.textTheme.headlineMedium),
                      Text('kcal đã nạp', style: theme.textTheme.labelSmall),
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
