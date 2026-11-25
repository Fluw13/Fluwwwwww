import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/domain/card_nutrition.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/presentation/food_image.dart';
import 'package:fluw/features/search/presentation/large_text.dart';
import 'package:fluw/features/search/presentation/per100_stats.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

class FoodResultCard extends StatelessWidget {
  const FoodResultCard({required this.item, required this.onTap, super.key});

  final FoodItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final large = usesLargeText(context);
    // "Coca-Cola" by "Coca-Cola" says it once.
    final brand = item.brand?.toLowerCase() == item.name?.toLowerCase() ? null : item.brand;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FoodThumbnail(item: item, size: large ? 48 : 72),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name ?? 'Chưa có tên', style: theme.textTheme.titleMedium),
                        if (brand != null)
                          Text(
                            brand,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        _SourceBadge(label: foodSourceLabel(item.source)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              if (hasCardNutrition(item))
                Per100Stats(facts: item.facts, showOpenHint: !large)
              else
                _NoDataBadge(text: hasProductLookup(item) ? 'Mở để xem số liệu' : 'Chưa có số liệu'),
              if (item.nutrientsSuspect)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_outlined, size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Số liệu nguồn có thể sai',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
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

/// The data source on every result, as Open Food Facts' and USDA's licences ask.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
    );
  }
}

/// In place of three "Chưa có" numbers, so a result without data reads as such at a glance; an Open Food Facts
/// product says the detail screen may have them.
class _NoDataBadge extends StatelessWidget {
  const _NoDataBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
