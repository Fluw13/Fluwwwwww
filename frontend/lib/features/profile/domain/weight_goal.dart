enum WeightGoal {
  lose,
  maintain,
  gain;

  static WeightGoal fromWeights({required double currentKg, required double targetKg}) {
    final differenceInTenthsOfKg = ((targetKg - currentKg) * 10).round();
    if (differenceInTenthsOfKg < 0) {
      return WeightGoal.lose;
    }
    if (differenceInTenthsOfKg > 0) {
      return WeightGoal.gain;
    }
    return WeightGoal.maintain;
  }
}
