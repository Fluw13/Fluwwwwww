import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

const double minHeightCm = 100;
const double maxHeightCm = 250;
const double minWeightKg = 20;
const double maxWeightKg = 300;

enum ProfileIssue {
  birthDateInFuture,
  birthDateTooOld,
  bmrFormulaMissing,
  pregnancyAnswerMissing,
  heightOutOfRange,
  weightOutOfRange,
  targetWeightOutOfRange,

  /// Losing weight down to a target below BMI 18.5 (underweight on the Asian scale).
  targetBmiTooLow,

  /// Losing weight while already underweight.
  loseWhenUnderweight,
  weeklyChangeMissing,
  weeklyChangeOutOfRange,
}

Set<ProfileIssue> validateProfile(HealthProfile profile, {required CalendarDate today}) {
  final age = ageInYears(birthDate: profile.birthDate, today: today);
  final isAdult = age >= minimumAgeYears;
  final isHeightValid = _isWithin(profile.heightCm, minHeightCm, maxHeightCm);
  final isWeightValid = _isWithin(profile.weightKg, minWeightKg, maxWeightKg);
  final isTargetWeightValid = _isWithin(profile.targetWeightKg, minWeightKg, maxWeightKg);
  final checksWeightLoss =
      isAdult && isHeightValid && isWeightValid && isTargetWeightValid && profile.goal == WeightGoal.lose;
  final isUnderweight = checksWeightLoss && _isUnderweight(profile.weightKg, profile.heightCm);
  final needsWeeklyChange =
      isAdult &&
      isWeightValid &&
      isTargetWeightValid &&
      profile.goal != WeightGoal.maintain &&
      profile.isPregnantOrBreastfeeding != true;
  final weeklyChangeKg = profile.weeklyChangeKg;

  return {
    if (profile.birthDate.isAfter(today)) ProfileIssue.birthDateInFuture,
    if (age > maximumAgeYears) ProfileIssue.birthDateTooOld,
    if (isAdult && profile.bmrFormula == null) ProfileIssue.bmrFormulaMissing,
    if (isAdult && profile.bmrFormula == BmrFormula.female && profile.isPregnantOrBreastfeeding == null)
      ProfileIssue.pregnancyAnswerMissing,
    if (!isHeightValid) ProfileIssue.heightOutOfRange,
    if (!isWeightValid) ProfileIssue.weightOutOfRange,
    if (!isTargetWeightValid) ProfileIssue.targetWeightOutOfRange,
    if (isUnderweight) ProfileIssue.loseWhenUnderweight,
    if (checksWeightLoss && !isUnderweight && _isUnderweight(profile.targetWeightKg, profile.heightCm))
      ProfileIssue.targetBmiTooLow,
    if (weeklyChangeKg == null && needsWeeklyChange) ProfileIssue.weeklyChangeMissing,
    if (weeklyChangeKg != null && !isValidWeeklyChangeKg(weeklyChangeKg)) ProfileIssue.weeklyChangeOutOfRange,
  };
}

bool _isWithin(double value, double min, double max) => value >= min && value <= max;

/// Judged on the truncated BMI the app shows, so the message always matches the number on screen.
bool _isUnderweight(double weightKg, double heightCm) =>
    Bmi.fromMeasurements(weightKg: weightKg, heightCm: heightCm).category == BmiCategory.underweight;
