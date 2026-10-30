import 'package:flutter/material.dart';

import '../core/theme/fluw_palette.dart';
import '../core/theme/score_colors.dart';
import '../models/score_level.dart';

class CircularScoreRing extends StatelessWidget {
  const CircularScoreRing({super.key, required this.score, this.size = 140.0});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final ScoreColors colors = palette.scoreColors(ScoreLevel.fromScore(score));
    final double stroke = size * 0.075;

    return Semantics(
      label: 'Điểm $score trên 100',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // An opaque fill keeps the glow outside the ring, so the number and
          // "/100" stay on the plain card colour.
          color: palette.surface,
          boxShadow: [
            if (palette.ringGlowOpacity > 0)
              BoxShadow(
                color: colors.ring.withValues(alpha: palette.ringGlowOpacity),
                blurRadius: size * 0.3,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The indicator strokes on its edge; the inset keeps the ring
            // inside [size] so it matches the skeleton circle.
            Padding(
              padding: EdgeInsets.all(stroke / 2),
              child: SizedBox.expand(
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: stroke,
                  strokeCap: StrokeCap.round,
                  backgroundColor: palette.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.ring),
                ),
              ),
            ),
            // With large system text the number shrinks to fit inside the
            // fixed ring; screen readers get the full label above.
            Padding(
              padding: EdgeInsets.all(stroke * 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: size * 0.3,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: size * 0.085,
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
