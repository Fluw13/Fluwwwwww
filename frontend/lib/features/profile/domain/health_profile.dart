import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

final class HealthProfile {
  const HealthProfile({
    required this.sex,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.trainingType,
    this.weeklyChangeKg,
  });

  final Sex sex;
  final CalendarDate birthDate;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final ActivityLevel activityLevel;
  final TrainingType trainingType;

  /// Only needed for adults who want to lose or gain weight.
  final double? weeklyChangeKg;

  WeightGoal get goal => WeightGoal.fromWeights(currentKg: weightKg, targetKg: targetWeightKg);
}
