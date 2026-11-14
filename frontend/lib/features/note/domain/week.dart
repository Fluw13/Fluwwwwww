import 'package:fluw/core/time/calendar_date.dart';

/// Weeks start on Monday, as Vietnamese calendars do.
CalendarDate mondayOf(CalendarDate day) {
  final weekday = DateTime.utc(day.year, day.month, day.day).weekday;
  return day.addDays(-(weekday - DateTime.monday));
}

List<CalendarDate> weekStartingOn(CalendarDate monday) =>
    List.unmodifiable([for (var offset = 0; offset < DateTime.daysPerWeek; offset++) monday.addDays(offset)]);
