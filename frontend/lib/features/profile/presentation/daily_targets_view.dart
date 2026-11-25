import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/core/theme/readable_color.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/nutrient_targets.dart';
import 'package:fluw/features/profile/domain/reference_weight.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';
import 'package:fluw/features/profile/presentation/target_tile.dart';
import 'package:fluw/features/profile/presentation/tile_grid.dart';

/// Shows every [DailyTargets] case; profiles without targets get an explanation instead of made-up numbers.
class DailyTargetsView extends StatelessWidget {
  const DailyTargetsView({required this.targets, super.key});

  final DailyTargets targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<NutrientColors>()!;
    // Chart colours such as the sugar orange are too light for an icon on the tile, so they are deepened to 3:1.
    Color icon(Color color) => readableOn(color, scheme.surfaceContainerLow, minContrast: 3);

    final content = switch (targets) {
      AdultTargets(
        :final calories,
        :final tdee,
        :final referenceWeight,
        :final protein,
        :final nutrients,
        :final waterMl,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The calorie target leads, full width, like the highlighted tile of the design; its note can be long.
            TargetTile(
              label: 'Năng lượng',
              value: formatWhole(calories.kcal),
              unit: 'kcal/ngày',
              note: _calorieNote(calories, tdee: tdee),
              icon: Icons.local_fire_department_outlined,
              iconColor: scheme.tertiary,
              background: scheme.tertiaryContainer,
              foreground: scheme.onTertiaryContainer,
              isLarge: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            TileGrid(
              children: [
                TargetTile(
                  label: 'Protein (đạm)',
                  value: _range(protein.minGrams, protein.maxGrams),
                  unit: 'g/ngày',
                  note: 'Đủ khi đạt ${formatDecimal(protein.minGrams)} g',
                  icon: Icons.egg_outlined,
                  iconColor: scheme.secondary,
                  background: scheme.secondaryContainer,
                  foreground: scheme.onSecondaryContainer,
                ),
                TargetTile(
                  label: 'Đường tổng (mức gợi ý)',
                  value: '< ${formatWhole(nutrients.sugarsMaxGrams)}',
                  unit: 'g/ngày',
                  icon: Icons.cookie_outlined,
                  iconColor: icon(colors.sugars),
                ),
                TargetTile(
                  label: 'Chất béo',
                  value: formatWhole(nutrients.fatGrams),
                  unit: 'g/ngày',
                  note: 'Béo bão hòa < ${formatWhole(nutrients.saturatedFatMaxGrams)} g',
                  icon: Icons.opacity_outlined,
                  iconColor: icon(colors.fat),
                ),
                TargetTile(
                  label: 'Carb (bột đường)',
                  value: switch (nutrients.carbohydratesGrams) {
                    final grams? => formatWhole(grams),
                    null => 'Chưa tính được',
                  },
                  unit: nutrients.carbohydratesGrams == null ? null : 'g/ngày',
                  icon: Icons.rice_bowl_outlined,
                  iconColor: icon(colors.carbohydrates),
                ),
                TargetTile(
                  label: 'Natri tối đa',
                  value: '< ${formatWhole(dailySodiumMaxMg)}',
                  unit: 'mg/ngày',
                  icon: Icons.grain_outlined,
                  iconColor: scheme.onSurfaceVariant,
                ),
                TargetTile(
                  label: 'Tổng lượng nước (gồm cả nước trong thức ăn)',
                  value: formatDecimal(waterMl / 1000),
                  unit: 'lít/ngày',
                  note: '35 ml mỗi kg: mức Fluw chọn, đối chiếu EFSA 2010',
                  icon: Icons.water_drop_outlined,
                  iconColor: icon(colors.water),
                ),
              ],
            ),
            if (referenceWeight.isCapped)
              _Note(
                'Đạm và nước tính theo cân nặng tham chiếu ${formatDecimal(referenceWeight.kg)} kg '
                '(BMI ${formatDecimal(referenceBmi)}), không theo cân nặng thật.',
              ),
            if (protein.group.needsKidneyCaution)
              const _Note('Nếu bạn có bệnh thận, hãy hỏi bác sĩ trước khi ăn nhiều đạm.'),
            const _Note('Khoảng 70–80% lượng nước đến từ đồ uống. Người bệnh tim, thận cần hỏi bác sĩ về lượng nước.'),
          ],
        ),
      BelowMinimumAge() => Text('Fluw dành cho người từ $minimumAgeYears tuổi.', style: theme.textTheme.bodyMedium),
      PregnancyOrBreastfeeding() => Text(
        'Nhu cầu năng lượng và đạm khi mang thai hoặc cho con bú khác người thường. '
        'Hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng.',
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
        Text('Số liệu là ước tính, không thay thế tư vấn y tế.', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

String _range(double min, double max) {
  final minText = formatWhole(min);
  final maxText = formatWhole(max);
  return minText == maxText ? minText : '$minText–$maxText';
}

String _calorieNote(CalorieTarget calories, {required double tdee}) {
  const why = 'để không ăn quá ít. Ăn thấp hơn cần bác sĩ theo dõi.';
  final kcal = formatWhole(calories.kcal);
  final raised = switch (calories.raisedTo) {
    CalorieFloor.bmr => 'Đã nâng lên bằng BMR (năng lượng cơ bản) $why',
    CalorieFloor.womenMinimum => 'Đã nâng lên mức tối thiểu $kcal kcal/ngày (nữ) $why',
    CalorieFloor.menMinimum => 'Đã nâng lên mức tối thiểu $kcal kcal/ngày (nam) $why',
    CalorieFloor.maintenance =>
      'Mức tiêu hao ước tính (TDEE) đã thấp hơn mức tối thiểu khi giảm cân (1,200 kcal nữ, 1,500 kcal nam), nên Fluw '
          'để mục tiêu bằng mức giữ cân. Muốn giảm cân, hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng.',
    null => null,
  };
  if (raised != null) {
    return raised;
  }
  final difference = (calories.kcal - tdee).round();
  if (difference == 0) {
    return 'Bằng mức tiêu hao ước tính (TDEE)';
  }
  final amount = formatWhole(difference.abs().toDouble());
  return difference < 0 ? 'Thâm hụt $amount kcal so với TDEE' : 'Dư $amount kcal so với TDEE';
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }
}
