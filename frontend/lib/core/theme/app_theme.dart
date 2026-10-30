import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/fluw_page_transitions_builder.dart';
import 'app_radius.dart';
import 'fluw_palette.dart';

class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'BeVietnamPro';

  static ThemeData light() => _build(FluwPalette.light, Brightness.light);

  static ThemeData dark() => _build(FluwPalette.dark, Brightness.dark);

  static ThemeData _build(FluwPalette palette, Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
    ).copyWith(
      primary: palette.primaryAction,
      onPrimary: palette.onPrimaryAction,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.border,
      outlineVariant: palette.border,
      error: palette.scorePoor.ring,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // A transparent app bar would otherwise get light status-bar icons in both themes.
        systemOverlayStyle: (brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.border,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: TextStyle(color: palette.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.border),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FluwPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FluwPageTransitionsBuilder(),
          TargetPlatform.linux: FluwPageTransitionsBuilder(),
          TargetPlatform.windows: FluwPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
