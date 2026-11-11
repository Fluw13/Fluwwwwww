import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';

final DateTime fixtureToday = DateTime(2026, 11, 11);

HealthProfile buildProfile({
  Sex sex = Sex.male,
  DateTime? birthDate,
  double heightCm = 175,
  double weightKg = 70,
  double targetWeightKg = 65,
  ActivityLevel activityLevel = ActivityLevel.moderate,
  TrainingType trainingType = TrainingType.strength,
  double weeklyChangeKg = 0.5,
}) {
  return HealthProfile(
    sex: sex,
    birthDate: birthDate ?? DateTime(2006, 5, 13),
    heightCm: heightCm,
    weightKg: weightKg,
    targetWeightKg: targetWeightKg,
    activityLevel: activityLevel,
    trainingType: trainingType,
    weeklyChangeKg: weeklyChangeKg,
  );
}
