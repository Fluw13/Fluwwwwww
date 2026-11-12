import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_palette.dart';

@immutable
final class NutrientColors extends ThemeExtension<NutrientColors> {
  const NutrientColors({
    required this.energy,
    required this.protein,
    required this.carbohydrates,
    required this.sugars,
    required this.fat,
    required this.water,
  });

  static const NutrientColors light = NutrientColors(
    energy: AppPalette.accent,
    protein: AppPalette.secondary,
    carbohydrates: AppPalette.accent,
    sugars: AppPalette.sugar,
    fat: AppPalette.fat,
    water: AppPalette.water,
  );

  static const NutrientColors dark = NutrientColors(
    energy: Color(0xFF4EDEA3),
    protein: Color(0xFF93CCFF),
    carbohydrates: Color(0xFF4EDEA3),
    sugars: Color(0xFFFFB95F),
    fat: Color(0xFFFFDDB8),
    water: Color(0xFF9ECAFF),
  );

  final Color energy;
  final Color protein;
  final Color carbohydrates;
  final Color sugars;
  final Color fat;
  final Color water;

  @override
  NutrientColors copyWith({
    Color? energy,
    Color? protein,
    Color? carbohydrates,
    Color? sugars,
    Color? fat,
    Color? water,
  }) {
    return NutrientColors(
      energy: energy ?? this.energy,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      sugars: sugars ?? this.sugars,
      fat: fat ?? this.fat,
      water: water ?? this.water,
    );
  }

  @override
  NutrientColors lerp(NutrientColors? other, double t) {
    if (other == null) {
      return this;
    }
    return NutrientColors(
      energy: Color.lerp(energy, other.energy, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carbohydrates: Color.lerp(carbohydrates, other.carbohydrates, t)!,
      sugars: Color.lerp(sugars, other.sugars, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      water: Color.lerp(water, other.water, t)!,
    );
  }
}
