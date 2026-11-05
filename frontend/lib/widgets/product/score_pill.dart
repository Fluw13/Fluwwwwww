import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';
import '../../core/theme/score_colors.dart';
import '../../models/score_level.dart';

/// Compact score for lists: colored dot + number + level, so the meaning
/// never relies on color alone.
class ScorePill extends StatelessWidget {
  const ScorePill({super.key, required this.score});

  final int? score;

  static String spokenLabelFor(int? score) {
    return score == null ? 'Chưa chấm điểm' : 'Điểm $score, ${ScoreLevel.fromScore(score).label}';
  }

  static String labelFor(int? score) {
    return score == null ? 'Chưa chấm' : '$score · ${ScoreLevel.fromScore(score).label}';
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final int? score = this.score;
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
