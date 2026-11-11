import 'package:fluw/features/profile/domain/weight_goal.dart';

const double maxWeeklyChangeKg = 0.5;

// About 7700 kcal per kg of body weight; gives the ±550 kcal/day for 0.5 kg/week that FLuw approved.
const double _kcalPerKgBodyWeight = 7700;

final class CalorieTarget {
  const CalorieTarget({required this.kcal, required this.isRaisedToBmr});

  final double kcal;
  final bool isRaisedToBmr;
}

bool isValidWeeklyChangeKg(double weeklyChangeKg) {
  if (!weeklyChangeKg.isFinite) {
    return false;
  }
  final hundredthsOfKg = (weeklyChangeKg * 100).round();
  return hundredthsOfKg > 0 && hundredthsOfKg <= (maxWeeklyChangeKg * 100).round();
}

CalorieTarget calculateCalorieTarget({
  required double bmr,
  required double tdee,
  required WeightGoal goal,
  double? weeklyChangeKg,
}) {
  switch (goal) {
    case WeightGoal.maintain:
      return CalorieTarget(kcal: tdee, isRaisedToBmr: false);
    case WeightGoal.gain:
      return CalorieTarget(kcal: tdee + _dailyChangeKcal(weeklyChangeKg), isRaisedToBmr: false);
    case WeightGoal.lose:
      final kcal = tdee - _dailyChangeKcal(weeklyChangeKg);
      return kcal < bmr
          ? CalorieTarget(kcal: bmr, isRaisedToBmr: true)
          : CalorieTarget(kcal: kcal, isRaisedToBmr: false);
  }
}

double _dailyChangeKcal(double? weeklyChangeKg) {
  if (weeklyChangeKg == null || !isValidWeeklyChangeKg(weeklyChangeKg)) {
    throw ArgumentError.value(weeklyChangeKg, 'weeklyChangeKg', 'Phải lớn hơn 0 và không quá $maxWeeklyChangeKg kg');
  }
  return weeklyChangeKg * _kcalPerKgBodyWeight / DateTime.daysPerWeek;
}
