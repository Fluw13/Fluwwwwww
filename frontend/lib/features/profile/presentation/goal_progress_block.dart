import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/goal_duration.dart';
import 'package:fluw/features/profile/domain/goal_progress.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/weight_entry.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

/// The target weight, how far the weigh-ins have come towards it and the estimated pace, on a tinted block.
class GoalProgressBlock extends ConsumerWidget {
  const GoalProgressBlock({required this.profile, required this.targets, super.key});

  final HealthProfile profile;
  final DailyTargets targets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entries = ref.watch(weightLogProvider).value ?? const <WeightEntry>[];
    final progress = _progress(entries);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.inner),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Text('Cân nặng mong muốn', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              Text.rich(
                TextSpan(
                  text: formatDecimal(profile.targetWeightKg),
                  style: theme.textTheme.numberMedium,
                  children: [TextSpan(text: ' kg', style: theme.textTheme.bodyMedium)],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: theme.extension<NutrientColors>()!.energy,
              backgroundColor: colors.surfaceContainerHighest,
              semanticsLabel: 'Tiến độ đến cân nặng mong muốn',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  'Từ ${formatDecimal(entries.first.weightKg)} kg ngày ${calendarDateLabel(entries.first.date)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Đã đạt ${(progress * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(_goalNote(), style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface)),
        ],
      ),
    );
  }

  /// Measured from the first weigh-in, and only while that weigh-in lies on the planned side of the target: after
  /// the target changes direction the old history says nothing about the new plan. Weight changes for other reasons
  /// while pregnant or breastfeeding, and Fluw sets no targets then, so no progress shows.
  double? _progress(List<WeightEntry> entries) {
    if (profile.isPregnantOrBreastfeeding == true || entries.length < 2 || profile.plannedGoal == WeightGoal.maintain) {
      return null;
    }
    final start = entries.first.weightKg;
    if (WeightGoal.fromWeights(currentKg: start, targetKg: profile.targetWeightKg) != profile.plannedGoal) {
      return null;
    }
    return goalProgress(startKg: start, currentKg: profile.weightKg, targetKg: profile.targetWeightKg);
  }

  String _goalNote() {
    if (profile.hasReachedTarget) {
      return 'Đã đạt cân nặng mong muốn';
    }
    final goal = profile.goal;
    if (goal == WeightGoal.maintain) {
      return weightGoalLabel(goal);
    }
    final difference = formatDecimal((profile.targetWeightKg - profile.weightKg).abs());
    final summary = '${weightGoalLabel(goal)} $difference kg';
    // Only a valid adult profile has a calorie target and a valid speed; the targets card explains the other cases.
    final targets = this.targets;
    if (targets is! AdultTargets) {
      return summary;
    }
    final calories = targets.calories;
    final isRaised = calories.isRaisedToMinimum;
    // A raised target changes the weight more slowly than the chosen speed.
    final weeklyChangeKg = isRaised
        ? weeklyChangeKgFromDailyGap(targets.tdee - calories.kcal)
        : profile.weeklyChangeKg!;
    // Compared as shown: a minimum at or above TDEE leaves no gap, and "0 kg/tuần" would mean never.
    if ((weeklyChangeKg * 100).round() <= 0) {
      return '$summary · chưa ước tính được thời gian';
    }
    final speed = formatDecimal(weeklyChangeKg, maxFractionDigits: 2);
    final weeks = estimateWeeksToTarget(
      currentKg: profile.weightKg,
      targetKg: profile.targetWeightKg,
      weeklyChangeKg: weeklyChangeKg,
    );
    final slowing = goal == WeightGoal.lose ? 'cân thường giảm chậm dần' : 'cân thường tăng chậm dần';
    return '$summary · ${isRaised ? '≈ ' : ''}$speed kg/tuần · ít nhất khoảng $weeks tuần (ước tính; $slowing)';
  }
}
