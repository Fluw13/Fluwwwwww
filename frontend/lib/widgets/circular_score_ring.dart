import 'package:flutter/material.dart';

import '../core/theme/fluw_palette.dart';
import '../core/theme/score_colors.dart';

/// The total score as a ring. The ring colour comes from the level the backend
/// chose; the app never derives a level from the number. Screen readers get
/// the score from the card around it, so the ring itself is not announced.
class CircularScoreRing extends StatelessWidget {
  const CircularScoreRing({
    super.key,
    required this.score,
    required this.colors,
    this.size = 140.0,
  });

  final int score;
  final ScoreColors colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final double stroke = size * 0.075;

    return ExcludeSemantics(
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
                  value: score.clamp(0, 100) / 100,
                  strokeWidth: stroke,
                  strokeCap: StrokeCap.round,
                  backgroundColor: palette.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.ring),
                ),
              ),
            ),
            // With large system text the number shrinks to fit inside the
            // fixed ring.
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
