import 'package:flutter/material.dart';

import '../../core/format/score_format.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/score/fluw_score.dart';
import '../skeleton/skeleton_box.dart';

/// "Điểm thành phần" block: nutrition and additives scores with their weights.
class ScoreComponents extends StatelessWidget {
  const ScoreComponents({
    super.key,
    required FluwScore this.score,
    this.textAlign = TextAlign.center,
  });

  const ScoreComponents.loading({super.key, this.textAlign = TextAlign.center})
    : score = null;

  static const String title = 'Điểm thành phần';
  static const double titleSize = 12;
  static const double lineSize = 14;
  static const double lineHeight = 1.4;

  final FluwScore? score;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final FluwScore? score = this.score;
    final TextStyle lineStyle = TextStyle(
      fontSize: lineSize,
      height: lineHeight,
      color: palette.textPrimary,
    );
    final CrossAxisAlignment alignment = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    final List<Widget> lines = score == null
        ? const [
            SkeletonBox.text(
              width: 220,
              fontSize: lineSize,
              lineHeight: lineHeight,
            ),
            SkeletonBox.text(
              width: 200,
              fontSize: lineSize,
              lineHeight: lineHeight,
            ),
          ]
        : [
            Text(
              ScoreFormat.component(
                'Dinh dưỡng',
                ScoreFormat.nutritionValue(score.nutrition),
                score.nutritionWeight,
              ),
              textAlign: textAlign,
              style: lineStyle,
            ),
            Text(
              ScoreFormat.component(
                'Phụ gia',
                ScoreFormat.additivesValue(score.additives),
                score.additivesWeight,
              ),
              textAlign: textAlign,
              style: lineStyle,
            ),
          ];

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: titleSize,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...lines,
      ],
    );
  }
}
