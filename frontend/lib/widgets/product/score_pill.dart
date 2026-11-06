import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/score_level.dart';
import '../score/score_level_style.dart';

/// Compact score for lists: colored dot + number + the backend's level text,
/// so the meaning never relies on color alone. The app never derives a level
/// from the number.
class ScorePill extends StatelessWidget {
  const ScorePill({super.key, required this.score, this.level, this.label});

  static const String notEnoughData = 'Chưa đủ dữ liệu';

  final int? score;
  final ScoreLevel? level;
  final String? label;

  static String spokenLabelFor(int? score, String? label) {
    if (score == null) return 'Chưa đủ dữ liệu để tính điểm';
    return label == null
        ? 'Điểm $score trên 100'
        : 'Điểm $score trên 100, mức $label';
  }

  static String labelFor(int? score, String? label) {
    if (score == null) return notEnoughData;
    return label == null ? '$score' : '$score · $label';
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final int? score = this.score;
    final ScoreLevelStyle? style = score == null
        ? null
        : ScoreLevelStyle.of(context, level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style?.colors.container ?? palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: style?.colors.ring ?? palette.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              labelFor(score, label),
              semanticsLabel: spokenLabelFor(score, label),
              style: TextStyle(
                color: style?.colors.text ?? palette.textSecondary,
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
