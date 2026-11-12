import 'package:flutter/painting.dart';

/// Light-theme colours sampled from the Figma exports in `design/figma/`. The `on*Container`, `tertiaryContainer`
/// and the middle surface containers do not appear in the design; they are the matching Material 3 tones.
abstract final class AppPalette {
  static const Color primary = Color(0xFF006C49);
  static const Color accent = Color(0xFF10B981);
  static const Color primaryContainer = Color(0xFF6FFBBE);
  static const Color onPrimaryContainer = Color(0xFF002113);
  static const Color secondary = Color(0xFF006398);
  static const Color secondaryContainer = Color(0xFFCCE5FF);
  static const Color onSecondaryContainer = Color(0xFF001D31);
  static const Color tertiary = Color(0xFF855300);
  static const Color tertiaryContainer = Color(0xFFFFDDB8);
  static const Color onTertiaryContainer = Color(0xFF2A1700);
  static const Color sugar = Color(0xFFFEA619);
  static const Color fat = Color(0xFFFFB95F);
  static const Color water = Color(0xFF1965A7);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFF0EF);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceDim = Color(0xFFD2D9F4);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFE);
  static const Color surfaceContainerHigh = Color(0xFFE2E8FE);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);
  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF3C4A42);
}
