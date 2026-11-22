import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/features/search/presentation/large_text.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// The design's macro tiles, for the chosen portion: two per row, one per row with large text. "–" while there is no
/// valid portion, "Chưa có dữ liệu" where the source has nothing.
class PortionNutrientGrid extends StatelessWidget {
  const PortionNutrientGrid({required this.portion, super.key});

  static const List<Nutrient> shown = [
    Nutrient.proteinG,
    Nutrient.carbohydratesG,
    Nutrient.sugarsG,
    Nutrient.fatG,
    Nutrient.saturatedFatG,
    Nutrient.sodiumMg,
  ];

  /// Null while the portion field holds no valid amount.
  final Nutrients? portion;

  @override
  Widget build(BuildContext context) {
    final tiles = [for (final nutrient in shown) _NutrientTile(nutrient: nutrient, portion: portion)];
    final perRow = usesLargeText(context) ? 1 : 2;

    return Column(
      children: [
        for (var start = 0; start < tiles.length; start += perRow) ...[
          if (start > 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, tile) in tiles.skip(start).take(perRow).indexed) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: tile),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NutrientTile extends StatelessWidget {
  const _NutrientTile({required this.nutrient, required this.portion});

  final Nutrient nutrient;
  final Nutrients? portion;

  (IconData, Color) _icon(ThemeData theme) {
    final colors = theme.extension<NutrientColors>()!;
    return switch (nutrient) {
      Nutrient.proteinG => (Icons.egg_outlined, colors.protein),
      Nutrient.carbohydratesG => (Icons.grass, colors.carbohydrates),
      Nutrient.sugarsG => (Icons.grain, colors.sugars),
      Nutrient.fatG || Nutrient.saturatedFatG => (Icons.water_drop_outlined, colors.fat),
      Nutrient.sodiumMg || Nutrient.energyKcal => (Icons.science_outlined, theme.colorScheme.onSurfaceVariant),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final (icon, iconColor) = _icon(theme);
    final portion = this.portion;
    final value = portion?[nutrient];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(nutrientLabel(nutrient), style: muted)),
                  ExcludeSemantics(child: Icon(icon, size: 20, color: iconColor)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (value == null)
                Text(
                  portion == null ? '–' : 'Chưa có dữ liệu',
                  style: portion == null ? theme.textTheme.titleLarge : muted,
                )
              else
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: formatShownAmount(nutrient, value), style: theme.textTheme.titleLarge),
                      TextSpan(text: ' ${nutrientUnit(nutrient)}', style: muted),
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
