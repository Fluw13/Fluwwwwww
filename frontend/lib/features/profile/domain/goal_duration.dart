/// Whole weeks needed to reach the target at [weeklyChangeKg], rounded up; compared in 0.1 kg like WeightGoal so
/// float noise never adds a week.
int estimateWeeksToTarget({required double currentKg, required double targetKg, required double weeklyChangeKg}) {
  if (!(weeklyChangeKg > 0)) {
    throw ArgumentError.value(weeklyChangeKg, 'weeklyChangeKg', 'Phải lớn hơn 0');
  }
  final differenceInTenthsOfKg = ((targetKg * 10).round() - (currentKg * 10).round()).abs();
  final changeInTenthsOfKg = weeklyChangeKg * 10;
  return (differenceInTenthsOfKg / changeInTenthsOfKg - 1e-9).ceil();
}
