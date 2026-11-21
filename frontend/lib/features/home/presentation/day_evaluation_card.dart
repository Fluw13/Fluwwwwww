import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/fluw_thresholds.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/home/domain/day_evaluation.dart';

/// The end-of-day review of a finished day. Each line pairs an icon with words, so it never relies on colour alone.
class DayEvaluationCard extends StatelessWidget {
  const DayEvaluationCard({required this.title, required this.evaluation, this.unreadableCount = 0, super.key});

  final String title;
  final DayEvaluation evaluation;

  /// Diary rows that could not be read, left out of the verdicts.
  final int unreadableCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return SectionCard(
      title: title,
      children: [
        // Only what Fluw tracks is judged: fibre, vegetables and fruit are not in the data, so no "balanced" claim.
        if (evaluation.isBalanced)
          Text('Đạt các chỉ tiêu Fluw đang theo dõi.', style: theme.textTheme.bodyLarge)
        else
          Text('Một số chỉ tiêu chưa đạt:', style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final verdict in evaluation.verdicts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (verdict.status) {
                    _ when verdict.isGood => Icons.check_circle_outline,
                    VerdictStatus.maybeUnderLogged => Icons.info_outline,
                    _ => Icons.error_outline,
                  },
                  size: 20,
                  color: switch (verdict.status) {
                    _ when verdict.isGood => theme.colorScheme.primary,
                    VerdictStatus.maybeUnderLogged => theme.colorScheme.onSurfaceVariant,
                    // Total sugars has a suggestion, not a limit: the warning colour, not the error red.
                    VerdictStatus.over when verdict.nutrient == Nutrient.sugarsG => theme.colorScheme.tertiary,
                    _ => theme.colorScheme.error,
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(verdictText(verdict))),
              ],
            ),
          ),
        if (evaluation.hasMissingData) Text('Có món thiếu số liệu nên đánh giá có thể chưa đủ.', style: muted),
        if (unreadableCount > 0)
          Text(
            'Có $unreadableCount món không đọc được nên không tính vào đánh giá.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        Text('Đánh giá ước tính, không thay thế tư vấn y tế.', style: muted),
      ],
    );
  }
}

String verdictText(NutrientVerdict verdict) {
  final label = switch (verdict.nutrient) {
    Nutrient.energyKcal => 'Năng lượng',
    Nutrient.proteinG => 'Protein (đạm)',
    Nutrient.sugarsG => 'Đường tổng',
    Nutrient.saturatedFatG => 'Béo bão hòa',
    Nutrient.sodiumMg => 'Natri',
    Nutrient.carbohydratesG => 'Carb (bột đường)',
    Nutrient.fatG => 'Chất béo',
  };
  final unit = switch (verdict.nutrient) {
    Nutrient.energyKcal => 'kcal',
    Nutrient.sodiumMg => 'mg',
    _ => 'g',
  };
  final gap = '${formatShownAmount(verdict.nutrient, verdict.gap)} $unit';
  final isSugar = verdict.nutrient == Nutrient.sugarsG;
  return switch (verdict.status) {
    VerdictStatus.onTarget => '$label: đạt mục tiêu (±${formatWhole(calorieToleranceShare * 100)}%)',
    VerdictStatus.reached => '$label: đủ mức tối thiểu',
    VerdictStatus.withinLimit when isSugar => '$label: trong mức gợi ý',
    VerdictStatus.withinLimit => '$label: trong giới hạn',
    VerdictStatus.maybeUnderLogged =>
      '$label: có thể chưa ghi đủ món (mới ghi ${formatShownAmount(verdict.nutrient, verdict.eaten!)} $unit)',
    VerdictStatus.below when verdict.nutrient == Nutrient.energyKcal => '$label: thấp hơn mục tiêu $gap',
    VerdictStatus.below => '$label: thiếu $gap',
    VerdictStatus.over when verdict.nutrient == Nutrient.energyKcal => '$label: vượt mục tiêu $gap',
    VerdictStatus.over when isSugar => '$label: cao hơn mức gợi ý $gap',
    VerdictStatus.over => '$label: vượt giới hạn $gap',
    VerdictStatus.incomplete => '$label: chưa đủ số liệu để đánh giá (${verdict.missingCount} món thiếu)',
    VerdictStatus.noData => '$label: chưa có dữ liệu',
  };
}
