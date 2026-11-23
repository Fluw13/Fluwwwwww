import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const String body = 'Inter';
  static const String heading = 'PlusJakartaSans';
}

/// The type scale read from the Figma file: headings and the header title are Plus Jakarta Sans 600, the large
/// numbers Plus Jakarta Sans 700, everything else Inter.
TextTheme buildTextTheme(TextTheme base, ColorScheme colorScheme) {
  TextStyle? heading(TextStyle? style) => style?.copyWith(fontFamily: AppFonts.heading, fontWeight: FontWeight.w600);
  TextStyle? body(TextStyle? style, FontWeight weight, double size, double lineHeight, {double letterSpacing = 0}) =>
      style?.copyWith(fontWeight: weight, fontSize: size, height: lineHeight / size, letterSpacing: letterSpacing);

  return base.copyWith(
    displayLarge: heading(base.displayLarge),
    displayMedium: heading(base.displayMedium),
    displaySmall: heading(base.displaySmall),
    headlineLarge: heading(base.headlineLarge),
    headlineMedium: base.headlineMedium?.copyWith(
      fontFamily: AppFonts.heading,
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 34 / 28,
      letterSpacing: -0.56,
    ),
    headlineSmall: heading(base.headlineSmall),
    titleLarge: heading(base.titleLarge)?.copyWith(fontSize: 18, height: 24 / 18, letterSpacing: 0),
    titleMedium: heading(base.titleMedium)?.copyWith(letterSpacing: 0),
    titleSmall: body(base.titleSmall, FontWeight.w600, 14, 20),
    bodyLarge: body(base.bodyLarge, FontWeight.w400, 14, 20),
    bodyMedium: body(base.bodyMedium, FontWeight.w500, 13, 16),
    bodySmall: body(base.bodySmall, FontWeight.w400, 12, 16)?.copyWith(color: colorScheme.onSurfaceVariant),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    labelSmall: body(base.labelSmall, FontWeight.w700, 11, 14, letterSpacing: 0.44),
  );
}

/// Styles of the design that have no Material slot.
extension AppTextStyles on TextTheme {
  /// Mid-size numbers, e.g. what is left today or a stat box value: Plus Jakarta Sans 700, 22/28.
  TextStyle? get numberMedium => headlineMedium?.copyWith(fontSize: 22, height: 28 / 22, letterSpacing: -0.33);

  /// A value beside its label, e.g. "78 g": Inter 700, 13/16.
  TextStyle? get value => bodyMedium?.copyWith(fontWeight: FontWeight.w700);
}
