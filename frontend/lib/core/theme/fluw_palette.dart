import 'package:flutter/material.dart';

import '../../models/score_level.dart';
import 'score_colors.dart';

@immutable
class FluwPalette extends ThemeExtension<FluwPalette> {
  const FluwPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentText,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.scoreGood,
    required this.scoreModerate,
    required this.scorePoor,
    required this.ringGlowOpacity,
  });

  static const FluwPalette light = FluwPalette(
    background: Color(0xFFF4F5F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF0EC),
    border: Color(0xFFE6E8E3),
    textPrimary: Color(0xFF121412),
    textSecondary: Color(0xFF59615B),
    accent: Color(0xFF009A52),
    accentText: Color(0xFF0B6B3A),
    primaryAction: Color(0xFF121412),
    onPrimaryAction: Color(0xFFFFFFFF),
    skeletonBase: Color(0xFFE9ECE7),
    skeletonHighlight: Color(0xFFF7F8F6),
    scoreGood: ScoreColors(
      ring: Color(0xFF009A52),
      text: Color(0xFF0B6B3A),
      container: Color(0xFFE3F6EA),
    ),
    scoreModerate: ScoreColors(
      ring: Color(0xFFB07800),
      text: Color(0xFF7A4E00),
      container: Color(0xFFFCF1D9),
    ),
    scorePoor: ScoreColors(
      ring: Color(0xFFE5484D),
      text: Color(0xFFA3252A),
      container: Color(0xFFFCE6E6),
    ),
    ringGlowOpacity: 0.18,
  );

  static const FluwPalette dark = FluwPalette(
    background: Color(0xFF0B0D0C),
    surface: Color(0xFF151917),
    surfaceMuted: Color(0xFF1E2321),
    border: Color(0xFF252B28),
    textPrimary: Color(0xFFF1F4F2),
    textSecondary: Color(0xFFA1ABA5),
    accent: Color(0xFF00E676),
    accentText: Color(0xFF3DF09A),
    primaryAction: Color(0xFF00E676),
    onPrimaryAction: Color(0xFF06110B),
    skeletonBase: Color(0xFF1E2321),
    skeletonHighlight: Color(0xFF2A312D),
    scoreGood: ScoreColors(
      ring: Color(0xFF00E676),
      text: Color(0xFF3DF09A),
      container: Color(0xFF123624),
    ),
    scoreModerate: ScoreColors(
      ring: Color(0xFFF5B83D),
      text: Color(0xFFF7C35A),
      container: Color(0xFF342F1C),
    ),
    scorePoor: ScoreColors(
      ring: Color(0xFFFF6B6B),
      text: Color(0xFFFF8A8A),
      container: Color(0xFF362423),
    ),
    ringGlowOpacity: 0.3,
  );

  static FluwPalette forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentText;
  final Color primaryAction;
  final Color onPrimaryAction;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final ScoreColors scoreGood;
  final ScoreColors scoreModerate;
  final ScoreColors scorePoor;
  final double ringGlowOpacity;

  ScoreColors scoreColors(ScoreLevel level) {
    return switch (level) {
      ScoreLevel.good => scoreGood,
      ScoreLevel.moderate => scoreModerate,
      ScoreLevel.poor => scorePoor,
    };
  }

  @override
  FluwPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? accentText,
    Color? primaryAction,
    Color? onPrimaryAction,
    Color? skeletonBase,
    Color? skeletonHighlight,
    ScoreColors? scoreGood,
    ScoreColors? scoreModerate,
    ScoreColors? scorePoor,
    double? ringGlowOpacity,
  }) {
    return FluwPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      primaryAction: primaryAction ?? this.primaryAction,
      onPrimaryAction: onPrimaryAction ?? this.onPrimaryAction,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      scoreGood: scoreGood ?? this.scoreGood,
      scoreModerate: scoreModerate ?? this.scoreModerate,
      scorePoor: scorePoor ?? this.scorePoor,
      ringGlowOpacity: ringGlowOpacity ?? this.ringGlowOpacity,
    );
  }

  @override
  FluwPalette lerp(FluwPalette? other, double t) {
    if (other == null) return this;
    return FluwPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      primaryAction: Color.lerp(primaryAction, other.primaryAction, t)!,
      onPrimaryAction: Color.lerp(onPrimaryAction, other.onPrimaryAction, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
      scoreGood: ScoreColors.lerp(scoreGood, other.scoreGood, t),
      scoreModerate: ScoreColors.lerp(scoreModerate, other.scoreModerate, t),
      scorePoor: ScoreColors.lerp(scorePoor, other.scorePoor, t),
      ringGlowOpacity: ringGlowOpacity + (other.ringGlowOpacity - ringGlowOpacity) * t,
    );
  }
}

extension FluwPaletteContext on BuildContext {
  /// Falls back to the built-in palette for the current brightness when a
  /// widget is rendered outside [AppTheme] (for example in isolated tests).
  FluwPalette get palette {
    final ThemeData theme = Theme.of(this);
    return theme.extension<FluwPalette>() ?? FluwPalette.forBrightness(theme.brightness);
  }
}
