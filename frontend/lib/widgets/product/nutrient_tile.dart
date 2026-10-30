import 'package:flutter/material.dart';

import '../../core/format/nutrient_format.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../skeleton/skeleton_box.dart';
import 'product_detail_metrics.dart';

class NutrientTile extends StatelessWidget {
  const NutrientTile({
    super.key,
    required this.icon,
    required this.label,
    required String this.value,
    required this.unit,
    required this.spokenUnit,
  });

  /// Icon and label are known before loading; only the value is a placeholder.
  const NutrientTile.loading({super.key, required this.icon, required this.label})
    : value = null,
      unit = '',
      spokenUnit = '';

  static const double _valueSize = 22;
  static const double _valueHeight = 1.2;
  static const double _labelSize = 13;
  static const double _labelHeight = 1.3;

  final IconData icon;
  final String label;
  final String? value;
  final String unit;
  final String spokenUnit;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? value = this.value;
    final bool isMissing = value == NutrientFormat.missing;

    final Widget valueWidget = value == null
        ? const SkeletonBox.text(width: 72, fontSize: _valueSize, lineHeight: _valueHeight)
        : Text.rich(
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: _valueSize,
                height: _valueHeight,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
              children: [
                if (!isMissing)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textSecondary),
                  ),
              ],
            ),
          );

    final Widget tile = Container(
      constraints: const BoxConstraints(minHeight: ProductDetailMetrics.nutrientTileMinHeight),
      padding: ProductDetailMetrics.nutrientTilePadding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md - 2),
            ),
            child: Icon(icon, size: 18, color: palette.textPrimary),
          ),
          valueWidget,
          Text(
            label,
            style: TextStyle(fontSize: _labelSize, height: _labelHeight, color: palette.textSecondary),
          ),
        ],
      ),
    );

    if (value == null) return tile;

    return Semantics(
      label: isMissing ? '$label: chưa có dữ liệu' : '$label: $value $spokenUnit',
      excludeSemantics: true,
      child: tile,
    );
  }
}
