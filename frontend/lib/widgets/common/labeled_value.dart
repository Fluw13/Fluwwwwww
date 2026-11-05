import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

/// "Label: value" on two lines, so long values (places, owners) never squeeze
/// the label at large text sizes. A missing value is written out.
class LabeledValue extends StatelessWidget {
  const LabeledValue({super.key, required this.label, required this.value});

  static const String missing = 'Chưa có dữ liệu';

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? value = this.value;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value ?? missing,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
                color: value == null
                    ? palette.textSecondary
                    : palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
