import 'package:flutter/material.dart';

import '../../core/format/nutrient_format.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/product/product_nutrition.dart';
import '../common/section_title.dart';
import 'nutrient_row.dart';
import 'nutrient_tile.dart';

/// Nutrition per 100 g or 100 ml: four main values as tiles, the rest as rows.
/// A missing value shows "—" and is read as "chưa có dữ liệu", never as 0.
class NutritionGrid extends StatelessWidget {
  const NutritionGrid({
    super.key,
    required this.values,
    required this.basis,
    this.prepared = false,
  }) : isLoading = false;

  const NutritionGrid.loading({super.key})
    : values = null,
      basis = null,
      prepared = false,
      isLoading = true;

  static const IconData _energyIcon = Icons.local_fire_department_outlined;
  static const IconData _proteinIcon = Icons.egg_outlined;
  static const IconData _fatIcon = Icons.water_drop_outlined;
  static const IconData _carbsIcon = Icons.grass_outlined;

  final NutrientValues? values;
  final NutritionBasis? basis;

  /// Values after preparation (instant noodles, powders).
  final bool prepared;
  final bool isLoading;

  String get title {
    final String per = basis == NutritionBasis.per100ml ? '100 ml' : '100 g';
    return prepared
        ? 'Dinh dưỡng sau khi pha, trên $per'
        : 'Dinh dưỡng trên $per';
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final NutrientValues? values = this.values;
    final List<double?> shown = [
      values?.energyKcal,
      values?.proteins,
      values?.fat,
      values?.carbohydrates,
      values?.energyKj,
      values?.saturatedFat,
      values?.sugars,
      values?.fiber,
      values?.salt,
    ];
    final bool hasMissingValue = !isLoading && shown.contains(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        const SizedBox(height: AppSpacing.sm + 2),
        _row(
          _energy(values),
          _grams(_proteinIcon, 'Chất đạm', values?.proteins),
        ),
        const SizedBox(height: AppSpacing.md),
        _row(
          _grams(_fatIcon, 'Chất béo', values?.fat),
          _grams(_carbsIcon, 'Carbohydrate', values?.carbohydrates),
        ),
        const SizedBox(height: AppSpacing.sm),
        _detail(
          'Năng lượng (kJ)',
          NutrientFormat.kilojoules(values?.energyKj),
          'kJ',
          'kilojun',
        ),
        _detail(
          'Chất béo bão hòa',
          NutrientFormat.grams(values?.saturatedFat),
          'g',
          'gam',
        ),
        _detail('Đường', NutrientFormat.grams(values?.sugars), 'g', 'gam'),
        _detail('Chất xơ', NutrientFormat.grams(values?.fiber), 'g', 'gam'),
        _detail('Muối', NutrientFormat.grams(values?.salt), 'g', 'gam'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hasMissingValue
              ? 'Nguồn: Open Food Facts · “${NutrientFormat.missing}” là chưa có dữ liệu'
              : 'Nguồn: Open Food Facts',
          style: TextStyle(
            fontSize: 12,
            height: 1.3,
            color: palette.textSecondary,
          ),
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

  Widget _energy(NutrientValues? values) => isLoading
      ? const NutrientTile.loading(icon: _energyIcon, label: 'Năng lượng')
      : NutrientTile(
          icon: _energyIcon,
          label: 'Năng lượng',
          value: NutrientFormat.kcal(values?.energyKcal),
          unit: 'kcal',
          spokenUnit: 'kilocalo',
        );

  Widget _grams(IconData icon, String label, double? value) {
    return isLoading
        ? NutrientTile.loading(icon: icon, label: label)
        : NutrientTile(
            icon: icon,
            label: label,
            value: NutrientFormat.grams(value),
            unit: 'g',
            spokenUnit: 'gam',
          );
  }

  Widget _detail(String label, String value, String unit, String spokenUnit) {
    return isLoading
        ? NutrientRow.loading(label: label)
        : NutrientRow(
            label: label,
            value: value,
            unit: unit,
            spokenUnit: spokenUnit,
          );
  }
}
