import 'package:fluw/features/profile/domain/health_condition.dart';

const double dailySodiumMaxMg = 2000;

const double _kcalPerGramProtein = 4;
const double _kcalPerGramCarbohydrate = 4;
const double _kcalPerGramSugar = 4;
const double _kcalPerGramFat = 9;

const double _fatShare = 0.25;
const double _saturatedFatShare = 0.10;
const double _saturatedFatShareForDyslipidemia = 0.07;
const double _sugarShare = 0.10;
const double _sugarShareWhenLimited = 0.05;

final class NutrientTargets {
  const NutrientTargets({
    required this.fatGrams,
    required this.saturatedFatMaxGrams,
    required this.sugarsMaxGrams,
    required this.carbohydratesGrams,
  });

  final double fatGrams;
  final double saturatedFatMaxGrams;
  final double sugarsMaxGrams;

  /// Null when protein and fat already use up the energy target (extreme profiles); never clamped to 0.
  final double? carbohydratesGrams;
}

NutrientTargets calculateNutrientTargets({
  required double kcal,
  required double proteinMinGrams,
  required Set<HealthCondition> conditions,
  required bool limitsSugar,
}) {
  final fatGrams = kcal * _fatShare / _kcalPerGramFat;
  final saturatedFatShare = conditions.contains(HealthCondition.dyslipidemia)
      ? _saturatedFatShareForDyslipidemia
      : _saturatedFatShare;
  final sugarShare = limitsSugar || conditions.contains(HealthCondition.diabetes)
      ? _sugarShareWhenLimited
      : _sugarShare;
  final carbohydrateKcal = kcal - proteinMinGrams * _kcalPerGramProtein - fatGrams * _kcalPerGramFat;

  return NutrientTargets(
    fatGrams: fatGrams,
    saturatedFatMaxGrams: kcal * saturatedFatShare / _kcalPerGramFat,
    sugarsMaxGrams: kcal * sugarShare / _kcalPerGramSugar,
    carbohydratesGrams: carbohydrateKcal < 0 ? null : carbohydrateKcal / _kcalPerGramCarbohydrate,
  );
}
