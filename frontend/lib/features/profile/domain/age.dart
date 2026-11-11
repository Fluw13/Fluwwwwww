const int adultAgeYears = 18;
const int minimumAgeYears = 14;

int ageInYears({required DateTime birthDate, required DateTime today}) {
  final hadBirthdayThisYear =
      today.month > birthDate.month || (today.month == birthDate.month && today.day >= birthDate.day);
  return today.year - birthDate.year - (hadBirthdayThisYear ? 0 : 1);
}
