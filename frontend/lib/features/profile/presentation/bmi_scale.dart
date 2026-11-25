import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';
import 'package:fluw/core/theme/readable_color.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

/// The BMI with its category and where it falls on the Asian scale, as a coloured strip.
class BmiScale extends StatelessWidget {
  const BmiScale({required this.bmi, super.key});

  final Bmi bmi;

  /// The scale is drawn from 15 to 30; each band takes a fixed share of the strip, not its real width, so the
  /// narrow 23–25 band stays visible.
  static const List<double> _edges = [15, 18.5, 23, 25, 30];
  static const List<int> _flex = [25, 35, 20, 20];
  static const List<String> _rangeLabels = ['< 18.5', '18.5–22.9', '23–24.9', '≥ 25'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bandColors = _bandColors(theme);
    final current = bmi.category.index;
    final value = formatDecimal(bmi.displayValue);
    final category = bmiCategoryLabel(bmi.category);
    final pillBackground = Color.alphaBlend(bandColors[current].withValues(alpha: 0.25), colors.surfaceContainerLowest);

    return Semantics(
      container: true,
      label: 'BMI (thang châu Á) $value, $category',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.inner),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.inner),
                      ),
                      child: Icon(Icons.monitor_weight_outlined, color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BMI (thang châu Á)', style: theme.textTheme.labelSmall),
                          Text(value, style: theme.textTheme.numberMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: 6),
                  decoration: BoxDecoration(color: pillBackground, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    category,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: readableOn(bandColors[current], pillBackground),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            LayoutBuilder(
              builder: (context, constraints) {
                const markerWidth = 4.0;
                final left = (_position(bmi.displayValue) * constraints.maxWidth - markerWidth / 2).clamp(
                  0.0,
                  constraints.maxWidth - markerWidth,
                );
                return SizedBox(
                  height: 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          width: constraints.maxWidth,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var band = 0; band < _flex.length; band++)
                                Expanded(
                                  flex: _flex[band],
                                  child: ColoredBox(color: bandColors[band]),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: markerWidth,
                          decoration: BoxDecoration(color: colors.onSurface, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (var band = 0; band < _flex.length; band++)
                  Expanded(
                    flex: _flex[band],
                    // The values are also in the label above and the spoken summary, so they may shrink to fit.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _rangeLabels[band],
                        style: band == current ? theme.textTheme.labelSmall : theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _bandColors(ThemeData theme) {
    final nutrients = theme.extension<NutrientColors>()!;
    // Softer ends like the design's pastel strip; the marker and the written category carry the meaning.
    Color soft(Color color, double alpha) =>
        Color.alphaBlend(color.withValues(alpha: alpha), theme.colorScheme.surfaceContainerLowest);
    return [soft(nutrients.water, 0.5), nutrients.energy, nutrients.fat, soft(theme.colorScheme.error, 0.4)];
  }

  /// Where [value] sits along the strip, from 0 to 1, proportionally inside its band.
  static double _position(double value) {
    final clamped = value.clamp(_edges.first, _edges.last);
    var start = 0.0;
    final total = _flex.reduce((a, b) => a + b);
    for (var band = 0; band < _flex.length; band++) {
      final share = _flex[band] / total;
      if (clamped < _edges[band + 1] || band == _flex.length - 1) {
        return start + (clamped - _edges[band]) / (_edges[band + 1] - _edges[band]) * share;
      }
      start += share;
    }
    return 1;
  }
}
