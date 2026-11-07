import 'package:flutter/material.dart';

import '../../core/format/score_format.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';
import '../../core/theme/score_colors.dart';
import '../../models/score_level.dart';

/// Compact score for lists: colored dot + number + level, so the meaning
/// never relies on color alone.
class ScorePill extends StatelessWidget {
  const ScorePill({super.key, required this.score});

  /// Fluw Nutrition Score (0-10); null when the product is not scored.
  final double? score;

  static String spokenLabelFor(double? score) {
    return score == null
        ? 'Chưa chấm điểm'
        : 'Điểm ${ScoreFormat.fns(score)} trên 10, ${ScoreLevel.fromScore(score).label}';
  }

  static String labelFor(double? score) {
    return score == null ? 'Chưa chấm' : '${ScoreFormat.fns(score)} · ${ScoreLevel.fromScore(score).label}';
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final double? score = this.score;
    final ScoreColors? colors = score == null ? null : palette.scoreColors(ScoreLevel.fromScore(score));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors?.container ?? palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: colors?.ring ?? palette.textSecondary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              labelFor(score),
              semanticsLabel: spokenLabelFor(score),
              style: TextStyle(
                color: colors?.text ?? palette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
