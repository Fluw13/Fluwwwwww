import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/meal_placement.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/time/calendar_date.dart';

/// The diary day and slot a food is logged into.
final class DiaryTarget {
  const DiaryTarget({required this.day, required this.slot});

  /// The slot happening at [now], on the diary day it belongs to (00:00 is still the previous day's Tối). Taken from
  /// the same clock as the eating time, so the day and the slot can never disagree.
  factory DiaryTarget.current(DateTime now) {
    final (:day, :slot) = placeMeal(now);
    return DiaryTarget(day: day, slot: slot);
  }

  final CalendarDate day;
  final MealSlot slot;

  @override
  bool operator ==(Object other) => other is DiaryTarget && other.day == day && other.slot == slot;

  @override
  int get hashCode => Object.hash(day, slot);
}

/// Set by the diary when the user taps "add" in a slot, so the screen that logs the food starts on that day and slot.
/// Cleared once a food is logged.
final diaryTargetProvider = NotifierProvider<DiaryTargetNotifier, DiaryTarget?>(DiaryTargetNotifier.new);

class DiaryTargetNotifier extends Notifier<DiaryTarget?> {
  @override
  DiaryTarget? build() => null;

  void choose(DiaryTarget? target) => state = target;
}
