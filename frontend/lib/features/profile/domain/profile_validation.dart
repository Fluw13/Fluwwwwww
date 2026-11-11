import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/age.dart';
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
  heightOutOfRange,
  weightOutOfRange,
  targetWeightOutOfRange,
  weeklyChangeMissing,
  weeklyChangeOutOfRange,
}

Set<ProfileIssue> validateProfile(HealthProfile profile, {required CalendarDate today}) {
  final age = ageInYears(birthDate: profile.birthDate, today: today);
  final isWeightValid = _isWithin(profile.weightKg, minWeightKg, maxWeightKg);
  final isTargetWeightValid = _isWithin(profile.targetWeightKg, minWeightKg, maxWeightKg);
  final needsWeeklyChange =
      age >= adultAgeYears && isWeightValid && isTargetWeightValid && profile.goal != WeightGoal.maintain;
  final weeklyChangeKg = profile.weeklyChangeKg;

  return {
    if (profile.birthDate.isAfter(today)) ProfileIssue.birthDateInFuture,
    if (age > maximumAgeYears) ProfileIssue.birthDateTooOld,
    if (!_isWithin(profile.heightCm, minHeightCm, maxHeightCm)) ProfileIssue.heightOutOfRange,
    if (!isWeightValid) ProfileIssue.weightOutOfRange,
    if (!isTargetWeightValid) ProfileIssue.targetWeightOutOfRange,
    if (weeklyChangeKg == null && needsWeeklyChange) ProfileIssue.weeklyChangeMissing,
    if (weeklyChangeKg != null && !isValidWeeklyChangeKg(weeklyChangeKg)) ProfileIssue.weeklyChangeOutOfRange,
  };
}

bool _isWithin(double value, double min, double max) => value >= min && value <= max;
