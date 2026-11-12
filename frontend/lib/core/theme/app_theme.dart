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
    return ColorScheme.fromSeed(seedColor: AppPalette.accent).copyWith(
      primary: AppPalette.primary,
      onPrimary: Colors.white,
      primaryContainer: AppPalette.primaryContainer,
      secondary: AppPalette.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppPalette.secondaryContainer,
      tertiary: AppPalette.tertiary,
      onTertiary: Colors.white,
      error: AppPalette.error,
      onError: Colors.white,
      errorContainer: AppPalette.errorContainer,
      surface: AppPalette.surface,
      onSurface: AppPalette.onSurface,
      onSurfaceVariant: AppPalette.onSurfaceVariant,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppPalette.surfaceContainerLow,
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
}
