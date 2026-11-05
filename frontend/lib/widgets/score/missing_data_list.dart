import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

/// Bulleted list of what the score still needs, using the backend's labels.
class MissingDataList extends StatelessWidget {
  const MissingDataList({
    super.key,
    required this.labels,
    this.title = 'Còn thiếu:',
    this.textAlign = TextAlign.start,
  });

  final List<String> labels;
  final String title;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final FluwPalette palette = context.palette;
    final TextStyle style = TextStyle(
      fontSize: 14,
      height: 1.45,
      color: palette.textPrimary,
    );
    final CrossAxisAlignment alignment = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: style.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final String label in labels)
          Text('• $label', textAlign: textAlign, style: style),
      ],
    );
  }
}
