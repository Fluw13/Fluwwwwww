import 'package:flutter/material.dart';

import '../../core/theme/fluw_palette.dart';
import '../../core/theme/score_colors.dart';
import '../../models/score_level.dart';

/// Colours and icon for a score level. Bright level colours are only used for
/// rings and backgrounds; text uses the darker `text` colour, which is tested
/// for contrast. A level this app does not know gets neutral colours.
class ScoreLevelStyle {
  const ScoreLevelStyle({required this.colors, required this.icon});

  factory ScoreLevelStyle.of(BuildContext context, ScoreLevel? level) {
    final FluwPalette palette = context.palette;
    return switch (level) {
      ScoreLevel.good => ScoreLevelStyle(
        colors: palette.scoreColors(ScoreLevel.good),
        icon: Icons.check_circle_outline,
      ),
      ScoreLevel.moderate => ScoreLevelStyle(
        colors: palette.scoreColors(ScoreLevel.moderate),
        icon: Icons.info_outline,
      ),
      ScoreLevel.limit => ScoreLevelStyle(
        colors: palette.scoreColors(ScoreLevel.limit),
        icon: Icons.do_not_disturb_on_outlined,
      ),
      null => ScoreLevelStyle(
        colors: ScoreColors(
          ring: palette.textSecondary,
          text: palette.textPrimary,
          container: palette.surfaceMuted,
        ),
        icon: Icons.help_outline,
      ),
    };
  }

  final ScoreColors colors;
  final IconData icon;
}
