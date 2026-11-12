import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const String body = 'Inter';
  static const String heading = 'PlusJakartaSans';
}

/// Headings use Plus Jakarta Sans as in the design; everything else keeps Inter from the theme.
TextTheme buildTextTheme(TextTheme base) {
  TextStyle? heading(TextStyle? style, FontWeight weight) =>
      style?.copyWith(fontFamily: AppFonts.heading, fontWeight: weight);

  return base.copyWith(
    displayLarge: heading(base.displayLarge, FontWeight.w800),
    displayMedium: heading(base.displayMedium, FontWeight.w800),
    displaySmall: heading(base.displaySmall, FontWeight.w800),
    headlineLarge: heading(base.headlineLarge, FontWeight.w700),
    headlineMedium: heading(base.headlineMedium, FontWeight.w700),
    headlineSmall: heading(base.headlineSmall, FontWeight.w700),
    titleLarge: heading(base.titleLarge, FontWeight.w700),
    titleMedium: heading(base.titleMedium, FontWeight.w600),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}
