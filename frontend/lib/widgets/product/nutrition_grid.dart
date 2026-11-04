import 'package:flutter/material.dart';

import '../../core/format/nutrient_format.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../common/section_title.dart';
import 'nutrient_tile.dart';

class NutritionGrid extends StatelessWidget {
  const NutritionGrid({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  }) : isLoading = false;

  const NutritionGrid.loading({super.key})
    : calories = null,
      protein = null,
      fat = null,
      carbs = null,
      isLoading = true;

  static const IconData _energyIcon = Icons.local_fire_department_outlined;
  static const IconData _proteinIcon = Icons.egg_outlined;
  static const IconData _fatIcon = Icons.water_drop_outlined;
  static const IconData _carbsIcon = Icons.grass_outlined;

  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final bool hasMissingValue = !isLoading && [calories, protein, fat, carbs].contains(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Dinh dưỡng trên 100 g'),
        const SizedBox(height: AppSpacing.sm + 2),
        _row(_energy(), _protein()),
        const SizedBox(height: AppSpacing.md),
        _row(_fat(), _carbs()),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hasMissingValue
              ? 'Nguồn: Open Food Facts · “${NutrientFormat.missing}” là chưa có dữ liệu'
              : 'Nguồn: Open Food Facts',
          style: TextStyle(fontSize: 12, height: 1.3, color: palette.textSecondary),
        ),
      ],
    );
  }

  Widget _row(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _energy() => isLoading
      ? const NutrientTile.loading(icon: _energyIcon, label: 'Năng lượng')
      : NutrientTile(
          icon: _energyIcon,
          label: 'Năng lượng',
          value: NutrientFormat.kcal(calories),
          unit: 'kcal',
          spokenUnit: 'kilocalo',
        );

  Widget _protein() => _grams(_proteinIcon, 'Chất đạm', protein);

  Widget _fat() => _grams(_fatIcon, 'Chất béo', fat);

  Widget _carbs() => _grams(_carbsIcon, 'Carbohydrate', carbs);

  Widget _grams(IconData icon, String label, double? value) {
    return isLoading
        ? NutrientTile.loading(icon: icon, label: label)
        : NutrientTile(icon: icon, label: label, value: NutrientFormat.grams(value), unit: 'g', spokenUnit: 'gam');
  }
}
