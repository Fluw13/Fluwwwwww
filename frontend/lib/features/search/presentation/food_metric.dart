import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// "Năng lượng / 165 kcal"; a missing value reads "Chưa có" instead of 0.
class FoodMetric extends StatelessWidget {
  const FoodMetric({required this.nutrient, required this.value, this.color, super.key});

  final Nutrient nutrient;
  final double? value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = this.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nutrientLabel(nutrient),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value == null ? 'Chưa có' : formatNutrientAmount(nutrient, value),
          style: theme.textTheme.labelLarge?.copyWith(
            color: value == null ? theme.colorScheme.onSurfaceVariant : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
