import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/energy.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/nutrient_targets.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';
import 'package:fluw/features/profile/domain/protein_target.dart';
import 'package:fluw/features/profile/domain/water_target.dart';

sealed class DailyTargets {
  const DailyTargets();
}

final class InvalidProfile extends DailyTargets {
  const InvalidProfile(this.issues);

  final Set<ProfileIssue> issues;
}

final class BelowMinimumAge extends DailyTargets {
  const BelowMinimumAge();
}

final class TeenTargets extends DailyTargets {
  const TeenTargets({required this.protein, required this.waterMl});

  final ProteinTarget protein;
  final double waterMl;
}

final class AdultTargets extends DailyTargets {
  const AdultTargets({
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.protein,
    required this.nutrients,
    required this.bmi,
    required this.waterMl,
  });

  final double bmr;
  final double tdee;
  final CalorieTarget calories;
  final ProteinTarget protein;
  final NutrientTargets nutrients;
  final Bmi bmi;
  final double waterMl;
}

DailyTargets calculateDailyTargets(HealthProfile profile, {required CalendarDate today}) {
  final issues = validateProfile(profile, today: today);
  if (issues.isNotEmpty) {
    return InvalidProfile(issues);
  }

  final age = ageInYears(birthDate: profile.birthDate, today: today);
  if (age < minimumAgeYears) {
    return const BelowMinimumAge();
  }

  final protein = ProteinTarget(
    group: ProteinGroup.select(ageYears: age, trainingType: profile.trainingType, goal: profile.goal),
    weightKg: profile.weightKg,
  );
  final waterMl = calculateWaterTargetMl(weightKg: profile.weightKg);
  if (age < adultAgeYears) {
    return TeenTargets(protein: protein, waterMl: waterMl);
  }

  final bmr = calculateBmr(
    formula: profile.bmrFormula!,
    weightKg: profile.weightKg,
    heightCm: profile.heightCm,
    ageYears: age,
  );
  final tdee = calculateTdee(bmr: bmr, activityLevel: profile.activityLevel);
  final calories = calculateCalorieTarget(
    bmr: bmr,
    tdee: tdee,
    goal: profile.goal,
    weeklyChangeKg: profile.weeklyChangeKg,
  );
  return AdultTargets(
    bmr: bmr,
    tdee: tdee,
    calories: calories,
    protein: protein,
    nutrients: calculateNutrientTargets(
      kcal: calories.kcal,
      proteinMinGrams: protein.minGrams,
      conditions: profile.conditions,
      limitsSugar: profile.limitsSugar,
    ),
    bmi: Bmi.fromMeasurements(weightKg: profile.weightKg, heightCm: profile.heightCm),
    waterMl: waterMl,
  );
}
