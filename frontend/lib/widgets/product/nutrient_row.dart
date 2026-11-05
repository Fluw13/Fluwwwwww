import 'package:flutter/material.dart';

import '../../core/format/nutrient_format.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../skeleton/skeleton_box.dart';

/// One line of the detailed nutrition list: label on the left, value on the
/// right. Long texts wrap instead of being cut.
class NutrientRow extends StatelessWidget {
  const NutrientRow({
    super.key,
    required this.label,
    required String this.value,
    required this.unit,
    required this.spokenUnit,
  });

  const NutrientRow.loading({super.key, required this.label})
    : value = null,
      unit = '',
      spokenUnit = '';

  static const double fontSize = 14;
  static const double lineHeight = 1.4;

  final String label;
  final String? value;
  final String unit;
  final String spokenUnit;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? value = this.value;
    final bool isMissing = value == NutrientFormat.missing;

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                height: lineHeight,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (value == null)
            const SkeletonBox.text(
              width: 56,
              fontSize: fontSize,
              lineHeight: lineHeight,
            )
          else
            Flexible(
              child: Text(
                isMissing ? value : '$value $unit',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: fontSize,
                  height: lineHeight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );

    if (value == null) return row;
    return Semantics(
      label: isMissing
          ? '$label: chưa có dữ liệu'
          : '$label: $value $spokenUnit',
      excludeSemantics: true,
      child: row,
    );
  }
}
