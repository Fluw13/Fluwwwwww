import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/presentation/food_metric.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

class FoodResultCard extends StatelessWidget {
  const FoodResultCard({required this.item, required this.onTap, super.key});

  final FoodItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NutrientColors>()!;
    final per100 = item.facts.per100;
    final subtitle = [?item.brand, foodSourceLabel(item.source)].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name ?? 'Chưa có tên', style: theme.textTheme.titleMedium),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trong 100 ${quantityUnitLabel(item.facts.unit)}',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FoodMetric(nutrient: Nutrient.energyKcal, value: per100[Nutrient.energyKcal]),
                        FoodMetric(
                          nutrient: Nutrient.proteinG,
                          value: per100[Nutrient.proteinG],
                          color: colors.protein,
                        ),
                        FoodMetric(nutrient: Nutrient.sugarsG, value: per100[Nutrient.sugarsG]),
                      ],
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
