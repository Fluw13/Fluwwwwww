import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/energy.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/nutrient_targets.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';
import 'package:fluw/features/profile/domain/protein_target.dart';
import 'package:fluw/features/profile/domain/reference_weight.dart';
import 'package:fluw/features/profile/domain/water_target.dart';

sealed class DailyTargets {
  const DailyTargets();
}

final class InvalidProfile extends DailyTargets {
  const InvalidProfile(this.issues);

  final Set<ProfileIssue> issues;
}

/// Under [minimumAgeYears]; profiles saved before Fluw became adults-only can still be like this.
final class BelowMinimumAge extends DailyTargets {
  const BelowMinimumAge();
}

/// Energy and protein needs in pregnancy and breastfeeding differ from the formulas, so there are no numbers at all.
final class PregnancyOrBreastfeeding extends DailyTargets {
  const PregnancyOrBreastfeeding();
}

final class AdultTargets extends DailyTargets {
  const AdultTargets({
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.referenceWeight,
    required this.protein,
    required this.nutrients,
    required this.bmi,
    required this.waterMl,
  });

  final double bmr;
  final double tdee;
  final CalorieTarget calories;

  /// What [protein] and [waterMl] are based on.
  final ReferenceWeight referenceWeight;
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
  if (profile.isPregnantOrBreastfeeding == true) {
    return const PregnancyOrBreastfeeding();
  }

  final formula = profile.bmrFormula!;
  final bmr = calculateBmr(formula: formula, weightKg: profile.weightKg, heightCm: profile.heightCm, ageYears: age);
  final tdee = calculateTdee(bmr: bmr, activityLevel: profile.activityLevel);
  final calories = calculateCalorieTarget(
    bmr: bmr,
    tdee: tdee,
    formula: formula,
    goal: profile.goal,
    weeklyChangeKg: profile.weeklyChangeKg,
  );
  final referenceWeight = ReferenceWeight.fromMeasurements(weightKg: profile.weightKg, heightCm: profile.heightCm);
  final protein = ProteinTarget(
    group: ProteinGroup.select(trainingType: profile.trainingType, goal: profile.goal),
    weightKg: referenceWeight.kg,
  );
  return AdultTargets(
    bmr: bmr,
    tdee: tdee,
    calories: calories,
    referenceWeight: referenceWeight,
    protein: protein,
    nutrients: calculateNutrientTargets(
      kcal: calories.kcal,
      proteinMinGrams: protein.minGrams,
      conditions: profile.conditions,
      limitsSugar: profile.limitsSugar,
    ),
    bmi: Bmi.fromMeasurements(weightKg: profile.weightKg, heightCm: profile.heightCm),
    waterMl: calculateWaterTargetMl(weightKg: referenceWeight.kg),
  );
}
