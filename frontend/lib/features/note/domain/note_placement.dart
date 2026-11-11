import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/domain/meal_slot.dart';

typedef NotePlacement = ({CalendarDate day, MealSlot slot});

const int _morningStartMinute = 6 * 60;
const int _afternoonStartMinute = 12 * 60 + 1;
const int _eveningStartMinute = 18 * 60 + 1;

/// [eatenAt] must be in the user's local time. Seconds are ignored; 00:00 counts as 24:00 of the previous day.
NotePlacement placeInNote(DateTime eatenAt) {
  final day = CalendarDate.fromDateTime(eatenAt);
  final minuteOfDay = eatenAt.hour * 60 + eatenAt.minute;

  if (minuteOfDay == 0) {
    return (day: day.addDays(-1), slot: MealSlot.evening);
  }
  final slot = switch (minuteOfDay) {
    < _morningStartMinute => MealSlot.night,
    < _afternoonStartMinute => MealSlot.morning,
    < _eveningStartMinute => MealSlot.afternoon,
    _ => MealSlot.evening,
  };
  return (day: day, slot: slot);
}
