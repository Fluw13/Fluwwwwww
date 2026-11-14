import 'package:fluw/core/diary/meal_placement.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/time/calendar_date.dart';

/// When a food logged into [slot] of [day] is recorded as eaten. Logging into the current slot keeps the real time;
/// logging into another slot uses a fixed time inside it, so the entry always lands where the user put it.
DateTime eatenAtFor({required CalendarDate day, required MealSlot slot, required DateTime now}) {
  final current = placeMeal(now);
  if (current.day == day && current.slot == slot) {
    return now;
  }
  final (hour, minute) = switch (slot) {
    MealSlot.night => (3, 0),
    MealSlot.morning => (9, 0),
    MealSlot.afternoon => (15, 0),
    MealSlot.evening => (21, 0),
  };
  return DateTime(day.year, day.month, day.day, hour, minute);
}
