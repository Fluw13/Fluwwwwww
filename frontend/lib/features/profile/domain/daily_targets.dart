import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/energy.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';
import 'package:fluw/features/profile/domain/protein_target.dart';

sealed class DailyTargets {
  const DailyTargets();
}

final class AdultTargets extends DailyTargets {
  const AdultTargets({required this.bmr, required this.tdee, required this.calories, required this.protein});

  final double bmr;
  final double tdee;
  final CalorieTarget calories;
  final ProteinTarget protein;
}

final class TeenTargets extends DailyTargets {
  const TeenTargets({required this.protein});

  final ProteinTarget protein;
}

final class BelowMinimumAge extends DailyTargets {
  const BelowMinimumAge();
}

DailyTargets calculateDailyTargets(HealthProfile profile, {required DateTime today}) {
  final issues = validateProfile(profile, today: today);
  if (issues.isNotEmpty) {
    throw ArgumentError.value(issues, 'profile', 'Hồ sơ không hợp lệ');
  }

  final age = ageInYears(birthDate: profile.birthDate, today: today);
  if (age < minimumAgeYears) {
    return const BelowMinimumAge();
  }

  final protein = ProteinTarget(
    group: ProteinGroup.select(ageYears: age, trainingType: profile.trainingType, goal: profile.goal),
    weightKg: profile.weightKg,
  );
  if (age < adultAgeYears) {
    return TeenTargets(protein: protein);
  }

  final bmr = calculateBmr(sex: profile.sex, weightKg: profile.weightKg, heightCm: profile.heightCm, ageYears: age);
  final tdee = calculateTdee(bmr: bmr, activityLevel: profile.activityLevel);
  return AdultTargets(
    bmr: bmr,
    tdee: tdee,
    calories: calculateCalorieTarget(bmr: bmr, tdee: tdee, goal: profile.goal, weeklyChangeKg: profile.weeklyChangeKg),
    protein: protein,
  );
}
