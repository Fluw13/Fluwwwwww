import 'package:fluw/core/time/calendar_date.dart';

/// Fluw is only for adults (FLuw decided on 18/11/2026); every formula it uses is for adults.
const int minimumAgeYears = 18;
const int maximumAgeYears = 100;

int ageInYears({required CalendarDate birthDate, required CalendarDate today}) {
  final hadBirthdayThisYear =
      today.month > birthDate.month || (today.month == birthDate.month && today.day >= birthDate.day);
  return today.year - birthDate.year - (hadBirthdayThisYear ? 0 : 1);
}

/// The last birth date that is [minimumAgeYears] old [today]. The year 18 years before a 29 February is never a leap
/// year, and someone born on 1 March is not yet of age by [ageInYears], so that day falls back to 28 February.
CalendarDate latestAdultBirthDate(CalendarDate today) {
  final isLeapDay = today.month == DateTime.february && today.day == 29;
  return CalendarDate(today.year - minimumAgeYears, today.month, isLeapDay ? 28 : today.day);
}
