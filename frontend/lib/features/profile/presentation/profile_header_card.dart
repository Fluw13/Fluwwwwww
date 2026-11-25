import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/app_card.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

/// The top of the profile: initial, name, age and sex, and the current weight goal.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({required this.profile, required this.age, super.key});

  final HealthProfile profile;
  final int age;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = profile.displayName;

    return AppCard(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        // The design's mint glow on the right of the card.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            stops: const [0.4, 1],
            colors: [colors.surfaceContainerLowest, colors.primaryContainer.withValues(alpha: 0.3)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primaryContainer, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 29,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: name == null
                        ? const Icon(Icons.person, size: 30)
                        : Text(name.characters.first.toUpperCase(), style: theme.textTheme.headlineSmall),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name ?? 'Hồ sơ của bạn', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text('$age tuổi · ${sexLabel(profile.sex)}', style: theme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.track_changes_outlined, size: 16, color: colors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Mục tiêu: ${weightGoalLabel(profile.goal)}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: colors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
