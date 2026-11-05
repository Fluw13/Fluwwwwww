import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../common/labeled_value.dart';
import '../common/section_title.dart';

class IngredientsSection extends StatelessWidget {
  const IngredientsSection({super.key, required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? text = this.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Thành phần'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          text ?? LabeledValue.missing,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: text == null ? palette.textSecondary : palette.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Theo Open Food Facts. Luôn kiểm tra nhãn bao bì trước khi dùng.',
          style: TextStyle(fontSize: 12, color: palette.textSecondary),
        ),
      ],
    );
  }
}
