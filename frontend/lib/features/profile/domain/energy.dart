import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/sex.dart';

/// Mifflin–St Jeor. Only valid for adults; growth changes the energy needs of younger people.
double calculateBmr({required Sex sex, required double weightKg, required double heightCm, required int ageYears}) {
  if (ageYears < adultAgeYears) {
    throw ArgumentError.value(ageYears, 'ageYears', 'BMR chỉ áp dụng từ $adultAgeYears tuổi');
  }
  final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
  return switch (sex) {
    Sex.male => base + 5,
    Sex.female => base - 161,
  };
}

double calculateTdee({required double bmr, required ActivityLevel activityLevel}) => bmr * activityLevel.factor;
