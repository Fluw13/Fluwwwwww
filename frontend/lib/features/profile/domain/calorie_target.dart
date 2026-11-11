import 'package:fluw/features/profile/domain/weight_goal.dart';

const double maxWeeklyChangeKg = 0.5;

// About 7700 kcal per kg of body weight; gives the ±550 kcal/day for 0.5 kg/week that FLuw approved.
const double _kcalPerKgBodyWeight = 7700;

final class CalorieTarget {
  const CalorieTarget({required this.kcal, required this.isRaisedToBmr});

  final double kcal;
  final bool isRaisedToBmr;
}

CalorieTarget calculateCalorieTarget({
  required double bmr,
  required double tdee,
  required WeightGoal goal,
  required double weeklyChangeKg,
}) {
  if (weeklyChangeKg <= 0 || weeklyChangeKg > maxWeeklyChangeKg) {
    throw ArgumentError.value(weeklyChangeKg, 'weeklyChangeKg', 'Phải lớn hơn 0 và không quá $maxWeeklyChangeKg kg');
  }
  final dailyChangeKcal = weeklyChangeKg * _kcalPerKgBodyWeight / DateTime.daysPerWeek;

  return switch (goal) {
    WeightGoal.maintain => CalorieTarget(kcal: tdee, isRaisedToBmr: false),
    WeightGoal.gain => CalorieTarget(kcal: tdee + dailyChangeKcal, isRaisedToBmr: false),
    WeightGoal.lose when tdee - dailyChangeKcal < bmr => CalorieTarget(kcal: bmr, isRaisedToBmr: true),
    WeightGoal.lose => CalorieTarget(kcal: tdee - dailyChangeKcal, isRaisedToBmr: false),
  };
}
