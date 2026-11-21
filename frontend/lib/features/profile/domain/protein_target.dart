import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

// Above this, people with kidney disease should ask a doctor before eating that much protein.
const double _kidneyCautionGramsPerKg = 1.2;

enum ProteinGroup {
  adult(0.8, 0.8),
  endurance(1.2, 1.4),
  strength(1.6, 2.2),
  // Hector & Phillips 2018.
  cutting(1.6, 2.4);

  const ProteinGroup(this.minGramsPerKg, this.maxGramsPerKg);

  final double minGramsPerKg;
  final double maxGramsPerKg;

  bool get needsKidneyCaution => maxGramsPerKg > _kidneyCautionGramsPerKg;

  static ProteinGroup select({required TrainingType trainingType, required WeightGoal goal}) {
    return switch (trainingType) {
      TrainingType.none => ProteinGroup.adult,
      TrainingType.endurance => ProteinGroup.endurance,
      TrainingType.strength => goal == WeightGoal.lose ? ProteinGroup.cutting : ProteinGroup.strength,
    };
  }
}

final class ProteinTarget {
  const ProteinTarget({required this.group, required this.weightKg});

  final ProteinGroup group;

  /// The reference weight (`ReferenceWeight`), which can be lower than the real one.
  final double weightKg;

  double get minGrams => weightKg * group.minGramsPerKg;

  double get maxGrams => weightKg * group.maxGramsPerKg;

  bool isReachedBy(double consumedGrams) => consumedGrams.isFinite && _toTenths(consumedGrams) >= _toTenths(minGrams);

  static int _toTenths(double grams) => (grams * 10).round();
}
