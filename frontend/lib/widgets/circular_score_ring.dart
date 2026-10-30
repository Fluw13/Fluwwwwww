import 'package:flutter/material.dart';

import '../core/theme/fluw_palette.dart';
import '../core/theme/score_colors.dart';
import '../models/score_level.dart';

class CircularScoreRing extends StatelessWidget {
  const CircularScoreRing({
    super.key,
    required this.score,
    this.size = 140.0,
  });

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final ScoreColors colors = palette.scoreColors(ScoreLevel.fromScore(score));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        boxShadow: [
          if (palette.ringGlowOpacity > 0)
            BoxShadow(
              color: colors.ring.withValues(alpha: palette.ringGlowOpacity),
              blurRadius: 24,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: palette.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(colors.ring),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: size * 0.1,
                  color: palette.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
