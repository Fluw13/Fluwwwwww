import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';

const double minHeightCm = 100;
const double maxHeightCm = 250;
const double minWeightKg = 20;
const double maxWeightKg = 300;

enum ProfileIssue {
  birthDateInFuture,
  heightOutOfRange,
  weightOutOfRange,
  targetWeightOutOfRange,
  weeklyChangeOutOfRange,
}

Set<ProfileIssue> validateProfile(HealthProfile profile, {required DateTime today}) {
  final todayDate = DateTime(today.year, today.month, today.day);
  final birthDate = DateTime(profile.birthDate.year, profile.birthDate.month, profile.birthDate.day);

  return {
    if (birthDate.isAfter(todayDate)) ProfileIssue.birthDateInFuture,
    if (!_isWithin(profile.heightCm, minHeightCm, maxHeightCm)) ProfileIssue.heightOutOfRange,
    if (!_isWithin(profile.weightKg, minWeightKg, maxWeightKg)) ProfileIssue.weightOutOfRange,
    if (!_isWithin(profile.targetWeightKg, minWeightKg, maxWeightKg)) ProfileIssue.targetWeightOutOfRange,
    if (profile.weeklyChangeKg <= 0 || profile.weeklyChangeKg > maxWeeklyChangeKg) ProfileIssue.weeklyChangeOutOfRange,
  };
}

bool _isWithin(double value, double min, double max) => value >= min && value <= max;
