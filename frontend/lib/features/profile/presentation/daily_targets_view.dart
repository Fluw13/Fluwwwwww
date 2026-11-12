import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/nutrient_targets.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';
import 'package:fluw/features/profile/presentation/target_tile.dart';
import 'package:fluw/features/profile/presentation/tile_grid.dart';

/// Shows every [DailyTargets] case; teens and invalid profiles get an explanation instead of made-up numbers.
class DailyTargetsView extends StatelessWidget {
  const DailyTargetsView({required this.targets, super.key});

  final DailyTargets targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NutrientColors>()!;

    final content = switch (targets) {
      AdultTargets(:final calories, :final tdee, :final protein, :final nutrients, :final waterMl) => TileGrid(
        children: [
          TargetTile(
            label: 'Năng lượng',
            value: formatWhole(calories.kcal),
            unit: 'kcal/ngày',
            note: _calorieNote(kcal: calories.kcal, tdee: tdee, isRaisedToBmr: calories.isRaisedToBmr),
            icon: Icons.local_fire_department_outlined,
            iconColor: colors.energy,
          ),
          TargetTile(
            label: 'Protein (đạm)',
            value: _range(protein.minGrams, protein.maxGrams),
            unit: 'g/ngày',
            note: 'Đủ khi đạt ${formatDecimal(protein.minGrams)} g',
            icon: Icons.egg_outlined,
            iconColor: colors.protein,
          ),
          TargetTile(
            label: 'Đường tổng tối đa',
            value: '< ${formatWhole(nutrients.sugarsMaxGrams)}',
            unit: 'g/ngày',
            icon: Icons.cookie_outlined,
            iconColor: colors.sugars,
          ),
          TargetTile(
            label: 'Chất béo',
            value: formatWhole(nutrients.fatGrams),
            unit: 'g/ngày',
            note: 'Béo bão hòa < ${formatWhole(nutrients.saturatedFatMaxGrams)} g',
            icon: Icons.opacity_outlined,
            iconColor: colors.fat,
          ),
          TargetTile(
            label: 'Tinh bột',
            value: switch (nutrients.carbohydratesGrams) {
              final grams? => formatWhole(grams),
              null => 'Chưa tính được',
            },
            unit: nutrients.carbohydratesGrams == null ? null : 'g/ngày',
            icon: Icons.rice_bowl_outlined,
            iconColor: colors.carbohydrates,
          ),
          TargetTile(
            label: 'Natri tối đa',
            value: '< ${formatWhole(dailySodiumMaxMg)}',
            unit: 'mg/ngày',
            icon: Icons.grain_outlined,
          ),
          TargetTile(
            label: 'Nước khuyến nghị',
            value: formatDecimal(waterMl / 1000),
            unit: 'lít/ngày',
            icon: Icons.water_drop_outlined,
            iconColor: colors.water,
          ),
        ],
      ),
      TeenTargets(:final protein, :final waterMl) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TileGrid(
            children: [
              TargetTile(
                label: 'Protein (đạm)',
                value: formatWhole(protein.minGrams),
                unit: 'g/ngày',
                icon: Icons.egg_outlined,
                iconColor: colors.protein,
              ),
              TargetTile(
                label: 'Nước khuyến nghị',
                value: formatDecimal(waterMl / 1000),
                unit: 'lít/ngày',
                icon: Icons.water_drop_outlined,
                iconColor: colors.water,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dưới $adultAgeYears tuổi cơ thể còn phát triển nên Fluw không tính calo. '
            'Hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng về lượng ăn phù hợp.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      BelowMinimumAge() => Text(
        'Fluw chỉ tính chỉ tiêu dinh dưỡng cho người từ $minimumAgeYears tuổi.',
        style: theme.textTheme.bodyMedium,
      ),
      InvalidProfile(:final issues) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hồ sơ cần sửa trước khi tính:', style: theme.textTheme.bodyMedium),
          for (final issue in issues)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '• ${profileIssueMessage(issue)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Số liệu là ước tính, không thay thế tư vấn y tế.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

String _range(double min, double max) {
  final minText = formatWhole(min);
  final maxText = formatWhole(max);
  return minText == maxText ? minText : '$minText–$maxText';
}

String _calorieNote({required double kcal, required double tdee, required bool isRaisedToBmr}) {
  if (isRaisedToBmr) {
    return 'Đã nâng lên bằng BMR để không ăn quá ít';
  }
  final difference = (kcal - tdee).round();
  if (difference == 0) {
    return 'Bằng mức tiêu hao ước tính (TDEE)';
  }
  final amount = formatWhole(difference.abs().toDouble());
  return difference < 0 ? 'Thâm hụt $amount kcal so với TDEE' : 'Dư $amount kcal so với TDEE';
}
