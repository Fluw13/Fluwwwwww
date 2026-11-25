import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/widgets/app_card.dart';
import 'package:fluw/core/widgets/erase_all_data_button.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/presentation/about_card.dart';
import 'package:fluw/features/profile/presentation/appearance_card.dart';
import 'package:fluw/features/profile/presentation/body_status_card.dart';
import 'package:fluw/features/profile/presentation/daily_targets_view.dart';
import 'package:fluw/features/profile/presentation/diet_preferences_card.dart';
import 'package:fluw/features/profile/presentation/health_notes_section.dart';
import 'package:fluw/features/profile/presentation/profile_header_card.dart';
import 'package:fluw/features/profile/presentation/profile_save_bar.dart';
import 'package:fluw/features/profile/presentation/weight_log_card.dart';

class ProfileOverview extends StatelessWidget {
  const ProfileOverview({
    required this.profile,
    required this.today,
    required this.onEdit,
    required this.onOpenPrivacy,
    required this.onOpenMethodology,
    required this.onEraseAllData,
    super.key,
  });

  final HealthProfile profile;
  final CalendarDate today;
  final VoidCallback onEdit;
  final VoidCallback onOpenPrivacy;

  /// Opens "Cách Fluw tính", the formulas and sources behind the targets.
  final VoidCallback onOpenMethodology;
  final VoidCallback onEraseAllData;

  @override
  Widget build(BuildContext context) {
    final age = ageInYears(birthDate: profile.birthDate, today: today);
    final targets = calculateDailyTargets(profile, today: today);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        ProfileHeaderCard(profile: profile, age: age),
        const SizedBox(height: AppSpacing.md),
        if (profile.hasReachedTarget) ...[
          _TargetReachedBanner(onUpdate: onEdit),
          const SizedBox(height: AppSpacing.md),
        ],
        BodyStatusCard(profile: profile, targets: targets, onEdit: onEdit),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Chỉ tiêu mỗi ngày',
          icon: Icons.track_changes_outlined,
          trailing: IconButton(
            onPressed: onOpenMethodology,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Cách Fluw tính',
          ),
          children: [DailyTargetsView(targets: targets)],
        ),
        const SizedBox(height: AppSpacing.lg),
        HealthNotesSection(profile: profile, onEdit: onEdit),
        const SizedBox(height: AppSpacing.lg),
        DietPreferencesCard(dietary: profile.dietary, limitsSugar: profile.limitsSugar),
        const SizedBox(height: AppSpacing.md),
        WeightLogCard(profile: profile),
        const SizedBox(height: AppSpacing.md),
        const AppearanceCard(),
        const SizedBox(height: AppSpacing.md),
        AboutCard(onOpenPrivacy: onOpenPrivacy, onOpenMethodology: onOpenMethodology),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onEdit,
          style: FilledButton.styleFrom(shape: largeButtonShape),
          icon: const Icon(Icons.edit_note),
          label: const Text('Cập nhật hồ sơ'),
        ),
        const SizedBox(height: AppSpacing.md),
        EraseAllDataButton(onPressed: onEraseAllData),
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
    final colors = theme.colorScheme;
    return AppCard(
      color: colors.primaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, color: colors.onPrimaryContainer),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đã đạt cân nặng mong muốn',
                  style: theme.textTheme.titleMedium?.copyWith(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Fluw đang tính chỉ tiêu để giữ cân. Đặt mục tiêu mới nếu bạn muốn tiếp tục tăng hoặc giảm.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonal(onPressed: onUpdate, child: const Text('Cập nhật mục tiêu')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
