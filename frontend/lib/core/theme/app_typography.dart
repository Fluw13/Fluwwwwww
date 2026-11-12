import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const String body = 'Inter';
  static const String heading = 'PlusJakartaSans';
}

/// Matched pixel by pixel against the design exports: headings, the header title and large numbers all use
/// Plus Jakarta Sans 600; everything else keeps Inter from the theme.
TextTheme buildTextTheme(TextTheme base) {
  TextStyle? heading(TextStyle? style) => style?.copyWith(fontFamily: AppFonts.heading, fontWeight: FontWeight.w600);

  return base.copyWith(
    displayLarge: heading(base.displayLarge),
    displayMedium: heading(base.displayMedium),
    displaySmall: heading(base.displaySmall),
    headlineLarge: heading(base.headlineLarge),
    headlineMedium: heading(base.headlineMedium),
    headlineSmall: heading(base.headlineSmall),
    titleLarge: heading(base.titleLarge),
    titleMedium: heading(base.titleMedium),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}
