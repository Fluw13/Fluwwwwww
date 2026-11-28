import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';

// The backend's rule (`areNutrientsSuspect` in backend/src/models/nutrients.js), applied to numbers typed from a
// label: a little over 100 g of macronutrients is rounding on the label, much more is a typo.
const double _maxMacronutrientsPer100 = 105;
const double _energyGapShare = 0.3;
const double _energyGapKcal = 40;

/// True when protein, carbohydrate and fat add up to more than 105 g per 100, or energy is far from 4 kcal/g protein
/// and carbohydrate plus 9 kcal/g fat. Only a warning: alcohol and polyols bring energy the formula does not count.
bool areNutrientsSuspect(Nutrients per100) {
  final protein = per100[Nutrient.proteinG];
  final carbohydrates = per100[Nutrient.carbohydratesG];
  final fat = per100[Nutrient.fatG];
  if ((protein ?? 0) + (carbohydrates ?? 0) + (fat ?? 0) > _maxMacronutrientsPer100) {
    return true;
  }
  final energy = per100[Nutrient.energyKcal];
  if (energy == null || protein == null || carbohydrates == null || fat == null) {
    return false;
  }
  final fromMacros = 4 * protein + 4 * carbohydrates + 9 * fat;
  final gap = (energy - fromMacros).abs();
  return gap > _energyGapKcal && gap > _energyGapShare * (energy > fromMacros ? energy : fromMacros);
}
