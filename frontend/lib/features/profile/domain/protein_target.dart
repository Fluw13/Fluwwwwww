import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

enum ProteinGroup {
  teen(0.85, 0.85),
  adult(0.8, 0.8),
  endurance(1.2, 1.4),
  strength(1.6, 2.2),
  cutting(1.8, 2.4);

  const ProteinGroup(this.minGramsPerKg, this.maxGramsPerKg);

  final double minGramsPerKg;
  final double maxGramsPerKg;

  static ProteinGroup select({required int ageYears, required TrainingType trainingType, required WeightGoal goal}) {
    if (ageYears < minimumAgeYears) {
      throw ArgumentError.value(ageYears, 'ageYears', 'Chỉ tính từ $minimumAgeYears tuổi');
    }
    if (ageYears < adultAgeYears) {
      return ProteinGroup.teen;
    }
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
  final double weightKg;

  double get minGrams => weightKg * group.minGramsPerKg;

  double get maxGrams => weightKg * group.maxGramsPerKg;

  bool isReachedBy(double consumedGrams) => consumedGrams.isFinite && _toTenths(consumedGrams) >= _toTenths(minGrams);

  static int _toTenths(double grams) => (grams * 10).round();
}
