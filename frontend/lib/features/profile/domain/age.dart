import 'package:fluw/core/time/calendar_date.dart';

const int minimumAgeYears = 14;
const int adultAgeYears = 18;
const int maximumAgeYears = 120;

int ageInYears({required CalendarDate birthDate, required CalendarDate today}) {
  final hadBirthdayThisYear =
      today.month > birthDate.month || (today.month == birthDate.month && today.day >= birthDate.day);
  return today.year - birthDate.year - (hadBirthdayThisYear ? 0 : 1);
}
