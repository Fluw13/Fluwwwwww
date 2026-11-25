import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/features/search/presentation/food_metric.dart';
import 'package:fluw/features/search/presentation/large_text.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// Energy, protein and sugars per 100 g/ml in the tinted box of the design, headed by the basis so the numbers are
/// never taken for the whole pack. With [showOpenHint] the round "+" of the design sits at the end; it only repeats
/// the card's own tap, so screen readers skip it.
class Per100Stats extends StatelessWidget {
  const Per100Stats({required this.facts, required this.showOpenHint, super.key});

  final NutritionFacts facts;
  final bool showOpenHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NutrientColors>()!;
    final per100 = facts.per100;
    final metrics = [
      FoodMetric(nutrient: Nutrient.energyKcal, value: per100[Nutrient.energyKcal], color: theme.colorScheme.tertiary),
      FoodMetric(nutrient: Nutrient.proteinG, value: per100[Nutrient.proteinG], color: colors.protein),
      FoodMetric(nutrient: Nutrient.sugarsG, value: per100[Nutrient.sugarsG]),
    ];
    final large = usesLargeText(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BasisLabel(text: per100Label(facts.unit)),
          const SizedBox(height: AppSpacing.sm),
          if (large)
            Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.sm, children: metrics)
          else
            Row(
              children: [
                Expanded(
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (index, metric) in metrics.indexed) ...[
                          if (index > 0) const VerticalDivider(width: AppSpacing.md),
                          Expanded(child: metric),
                        ],
                      ],
                    ),
                  ),
                ),
                if (showOpenHint) ...[const SizedBox(width: AppSpacing.sm), const _OpenHint()],
              ],
            ),
        ],
      ),
    );
  }
}

class _BasisLabel extends StatelessWidget {
  const _BasisLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OpenHint extends StatelessWidget {
  const _OpenHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          child: Icon(Icons.add, color: scheme.onPrimary),
        ),
      ),
    );
  }
}
