import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/goal_duration.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';
import 'package:fluw/features/profile/presentation/about_card.dart';
import 'package:fluw/features/profile/presentation/appearance_card.dart';
import 'package:fluw/features/profile/presentation/daily_targets_view.dart';
import 'package:fluw/features/profile/presentation/dietary_summary_card.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';
import 'package:fluw/features/profile/presentation/target_tile.dart';
import 'package:fluw/features/profile/presentation/tile_grid.dart';
import 'package:fluw/features/profile/presentation/weight_log_card.dart';

class ProfileOverview extends StatelessWidget {
  const ProfileOverview({required this.profile, required this.today, required this.onEdit, super.key});

  final HealthProfile profile;
  final CalendarDate today;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = ageInYears(birthDate: profile.birthDate, today: today);
    final targets = calculateDailyTargets(profile, today: today);
    final note = profile.conditionNote;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _Header(profile: profile, age: age),
        const SizedBox(height: AppSpacing.md),
        if (profile.hasReachedTarget) ...[
          _TargetReachedBanner(onUpdate: onEdit),
          const SizedBox(height: AppSpacing.md),
        ],
        SectionCard(
          title: 'Thể trạng & mục tiêu',
          children: [
            TileGrid(
              children: [
                TargetTile(label: 'Chiều cao', value: formatDecimal(profile.heightCm), unit: 'cm'),
                TargetTile(label: 'Cân nặng', value: formatDecimal(profile.weightKg), unit: 'kg'),
                // Taken from the targets, so a profile that fails validation (e.g. edited limits) shows no BMI.
                if (targets case AdultTargets(:final bmi)) _bmiTile(bmi),
                TargetTile(
                  label: 'Cân nặng mong muốn',
                  value: formatDecimal(profile.targetWeightKg),
                  unit: 'kg',
                  note: _goalNote(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${activityLevelLabel(profile.activityLevel)} · ${trainingTypeLabel(profile.trainingType)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Chỉ tiêu mỗi ngày',
          children: [DailyTargetsView(targets: targets)],
        ),
        if (profile.conditions.isNotEmpty || note != null) ...[
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Bệnh nền & ghi chú',
            accentColor: theme.colorScheme.tertiary,
            children: [
              for (final condition in profile.conditions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(healthConditionLabel(condition)),
                  subtitle: Text(healthConditionDescription(condition)),
                ),
              if (note != null)
                ListTile(contentPadding: EdgeInsets.zero, title: const Text('Ghi chú'), subtitle: Text(note)),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        WeightLogCard(profile: profile),
        const SizedBox(height: AppSpacing.md),
        DietarySummaryCard(dietary: profile.dietary),
        const SizedBox(height: AppSpacing.md),
        const AppearanceCard(),
        const SizedBox(height: AppSpacing.md),
        const AboutCard(),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Cập nhật hồ sơ'),
        ),
      ],
    );
  }

  Widget _bmiTile(Bmi bmi) {
    return TargetTile(
      label: 'BMI (thang châu Á)',
      value: formatDecimal(bmi.displayValue),
      note: bmiCategoryLabel(bmi.category),
    );
  }

  String _goalNote() {
    if (profile.hasReachedTarget) {
      return 'Đã đạt cân nặng mong muốn';
    }
    final goal = profile.goal;
    final weeklyChangeKg = profile.weeklyChangeKg;
    if (goal == WeightGoal.maintain) {
      return weightGoalLabel(goal);
    }
    final difference = formatDecimal((profile.targetWeightKg - profile.weightKg).abs());
    final summary = '${weightGoalLabel(goal)} $difference kg';
    // A stored speed outside the allowed range must not crash the page; the targets card lists the issue.
    if (weeklyChangeKg == null || !isValidWeeklyChangeKg(weeklyChangeKg)) {
      return summary;
    }
    final weeks = estimateWeeksToTarget(
      currentKg: profile.weightKg,
      targetKg: profile.targetWeightKg,
      weeklyChangeKg: weeklyChangeKg,
    );
    return '$summary · ${formatDecimal(weeklyChangeKg, maxFractionDigits: 2)} kg/tuần · khoảng $weeks tuần';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.age});

  final HealthProfile profile;
  final int age;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile.displayName;

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: name == null
              ? const Icon(Icons.person, size: 32)
              : Text(name.characters.first.toUpperCase(), style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name ?? 'Hồ sơ của bạn', style: theme.textTheme.headlineSmall),
              Text(
                '$age tuổi · ${sexLabel(profile.sex)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown once a weigh-in reaches the target; targets are then calculated for maintaining until the user sets a new one.
class _TargetReachedBanner extends StatelessWidget {
  const _TargetReachedBanner({required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đã đạt cân nặng mong muốn',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Fluw đang tính chỉ tiêu để giữ cân. Đặt mục tiêu mới nếu bạn muốn tiếp tục tăng hoặc giảm.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonal(onPressed: onUpdate, child: const Text('Cập nhật mục tiêu')),
          ],
        ),
      ),
    );
  }
}
