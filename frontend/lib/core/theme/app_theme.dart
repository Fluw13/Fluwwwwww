import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_palette.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(_lightScheme(), NutrientColors.light);

  static ThemeData dark() =>
      _build(ColorScheme.fromSeed(seedColor: AppPalette.accent, brightness: Brightness.dark), NutrientColors.dark);

  static ColorScheme _lightScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      primary: AppPalette.primary,
      onPrimary: Colors.white,
      primaryContainer: AppPalette.primaryContainer,
      onPrimaryContainer: AppPalette.onPrimaryContainer,
      surfaceTint: AppPalette.primary,
      secondary: AppPalette.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppPalette.secondaryContainer,
      onSecondaryContainer: AppPalette.onSecondaryContainer,
      tertiary: AppPalette.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppPalette.tertiaryContainer,
      onTertiaryContainer: AppPalette.onTertiaryContainer,
      error: AppPalette.error,
      onError: Colors.white,
      errorContainer: AppPalette.errorContainer,
      onErrorContainer: AppPalette.onErrorContainer,
      surface: AppPalette.surface,
      surfaceBright: AppPalette.surface,
      surfaceDim: AppPalette.surfaceDim,
      onSurface: AppPalette.onSurface,
      onSurfaceVariant: AppPalette.onSurfaceVariant,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppPalette.surfaceContainerLow,
      surfaceContainer: AppPalette.surfaceContainer,
      surfaceContainerHigh: AppPalette.surfaceContainerHigh,
      surfaceContainerHighest: AppPalette.surfaceContainerHighest,
    );
  }

  static ThemeData _build(ColorScheme colorScheme, NutrientColors nutrientColors) {
    final base = ThemeData(colorScheme: colorScheme, fontFamily: AppFonts.body);
    final textTheme = buildTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 2,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      // Filled, borderless fields with rounded corners, like the inputs in the design.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: _fieldBorder(Colors.transparent),
        enabledBorder: _fieldBorder(Colors.transparent),
        focusedBorder: _fieldBorder(colorScheme.primary),
        errorBorder: _fieldBorder(colorScheme.error),
        focusedErrorBorder: _fieldBorder(colorScheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      extensions: [nutrientColors],
    );
  }

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
    borderSide: BorderSide(color: color, width: 2),
  );
}
