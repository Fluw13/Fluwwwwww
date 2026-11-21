import 'dart:math';

import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

const double maxWeeklyChangeKg = 0.5;

// About 7700 kcal per kg of body weight; gives the ±550 kcal/day for 0.5 kg/week that FLuw approved.
const double _kcalPerKgBodyWeight = 7700;

/// The least a weight-loss target may suggest without a doctor: the low-calorie diet of NIH/NHLBI starts at 1,200 kcal
/// for women and 1,500 kcal for men. BMR is the energy at complete rest, not a safe intake, so it alone is no floor.
double minimumIntakeKcal(BmrFormula formula) => switch (formula) {
  BmrFormula.female => 1200,
  BmrFormula.male => 1500,
};

/// Which floor a weight-loss target was raised to.
enum CalorieFloor { bmr, womenMinimum, menMinimum }

final class CalorieTarget {
  const CalorieTarget({required this.kcal, required this.raisedTo});

  final double kcal;

  /// `null` when the target was not raised.
  final CalorieFloor? raisedTo;

  bool get isRaisedToMinimum => raisedTo != null;
}

bool isValidWeeklyChangeKg(double weeklyChangeKg) {
  if (!weeklyChangeKg.isFinite) {
    return false;
  }
  final hundredthsOfKg = (weeklyChangeKg * 100).round();
  return hundredthsOfKg > 0 && hundredthsOfKg <= (maxWeeklyChangeKg * 100).round();
}

/// The weekly change a daily gap of [dailyKcalGap] to TDEE gives, by the same 7700 kcal/kg rule as the target.
double weeklyChangeKgFromDailyGap(double dailyKcalGap) => dailyKcalGap * DateTime.daysPerWeek / _kcalPerKgBodyWeight;

CalorieTarget calculateCalorieTarget({
  required double bmr,
  required double tdee,
  required BmrFormula formula,
  required WeightGoal goal,
  double? weeklyChangeKg,
}) {
  switch (goal) {
    case WeightGoal.maintain:
      return CalorieTarget(kcal: tdee, raisedTo: null);
    case WeightGoal.gain:
      return CalorieTarget(kcal: tdee + _dailyChangeKcal(weeklyChangeKg), raisedTo: null);
    case WeightGoal.lose:
      final kcal = tdee - _dailyChangeKcal(weeklyChangeKg);
      final minimum = minimumIntakeKcal(formula);
      final floor = bmr >= minimum
          ? CalorieFloor.bmr
          : (formula == BmrFormula.female ? CalorieFloor.womenMinimum : CalorieFloor.menMinimum);
      final floorKcal = max(bmr, minimum);
      return kcal < floorKcal
          ? CalorieTarget(kcal: floorKcal, raisedTo: floor)
          : CalorieTarget(kcal: kcal, raisedTo: null);
  }
}

double _dailyChangeKcal(double? weeklyChangeKg) {
  if (weeklyChangeKg == null || !isValidWeeklyChangeKg(weeklyChangeKg)) {
    throw ArgumentError.value(weeklyChangeKg, 'weeklyChangeKg', 'Phải lớn hơn 0 và không quá $maxWeeklyChangeKg kg');
  }
  return weeklyChangeKg * _kcalPerKgBodyWeight / DateTime.daysPerWeek;
}
