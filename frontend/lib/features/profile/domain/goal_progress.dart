/// Share of the way from [startKg] to [targetKg] already covered, between 0 and 1. `null` when there is no distance
/// to cover (0.1 kg steps, like WeightGoal). Moving away from the target counts as 0, overshooting as 1.
double? goalProgress({required double startKg, required double currentKg, required double targetKg}) {
  final total = (targetKg * 10).round() - (startKg * 10).round();
  if (total == 0) {
    return null;
  }
  final covered = (currentKg * 10).round() - (startKg * 10).round();
  return (covered / total).clamp(0, 1).toDouble();
}
