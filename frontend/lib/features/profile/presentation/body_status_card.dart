import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/presentation/goal_progress_block.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';
import 'package:fluw/features/profile/presentation/tile_grid.dart';

/// "Thể trạng & mục tiêu": height, weight and BMI side by side, then the target weight and its progress.
class BodyStatusCard extends StatelessWidget {
  const BodyStatusCard({required this.profile, required this.targets, required this.onEdit, super.key});

  /// Three tiles share a row only when each keeps room for its number at the current text size.
  static const double _minTileWidth = 96;
  static const double _maxRowTextScale = 1.3;

  final HealthProfile profile;
  final DailyTargets targets;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final tiles = [
      _StatTile(label: 'Chiều cao', value: formatDecimal(profile.heightCm), unit: 'cm'),
      _StatTile(label: 'Cân nặng', value: formatDecimal(profile.weightKg), unit: 'kg'),
      // Taken from the targets, so a profile that fails validation (e.g. edited limits) shows no BMI.
      if (targets case AdultTargets(:final bmi)) _BmiTile(bmi: bmi),
    ];

    return SectionCard(
      title: 'Thể trạng & mục tiêu',
      icon: Icons.accessibility_new_outlined,
      trailing: TextButton(onPressed: onEdit, child: const Text('Chỉnh sửa')),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - AppSpacing.sm * (tiles.length - 1)) / tiles.length;
            if (tileWidth < _minTileWidth || textScale > _maxRowTextScale) {
              return TileGrid(children: tiles);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [for (final tile in tiles) Expanded(child: tile)],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        GoalProgressBlock(profile: profile, targets: targets),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.directions_run, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${activityLevelLabel(profile.activityLevel)} · ${trainingTypeLabel(profile.trainingType)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.unit, this.note, this.background, this.foreground});

  final String label;
  final String value;
  final String? unit;
  final String? note;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unit = this.unit;
    final note = this.note;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: background ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.inner),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: foreground ?? colors.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: value,
              style: theme.textTheme.numberMedium?.copyWith(color: foreground),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          if (note != null)
            Text(
              note,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

/// Tinted by category, like the design's mint "normal" tile; the category is also written out.
class _BmiTile extends StatelessWidget {
  const _BmiTile({required this.bmi});

  final Bmi bmi;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (bmi.category) {
      BmiCategory.normal => (colors.primaryContainer.withValues(alpha: 0.45), colors.onPrimaryContainer),
      BmiCategory.underweight || BmiCategory.overweight => (colors.tertiaryContainer, colors.onTertiaryContainer),
      BmiCategory.obese => (colors.errorContainer, colors.onErrorContainer),
    };
    return _StatTile(
      label: 'BMI (thang châu Á)',
      value: formatDecimal(bmi.displayValue),
      note: bmiCategoryLabel(bmi.category),
      background: Color.alphaBlend(background, colors.surfaceContainerLowest),
      foreground: foreground,
    );
  }
}
