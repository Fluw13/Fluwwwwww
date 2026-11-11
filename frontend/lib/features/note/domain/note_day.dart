import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/domain/meal_slot.dart';
import 'package:fluw/features/note/domain/note_entry.dart';

final class NoteDay {
  NoteDay._(this.date, Map<MealSlot, List<NoteEntry>> entriesBySlot)
    : entriesBySlot = Map.unmodifiable({
        for (final slot in MealSlot.values)
          slot: List<NoteEntry>.unmodifiable(<NoteEntry>[...?entriesBySlot[slot]]..sort(_byTimeThenId)),
      });

  final CalendarDate date;
  final Map<MealSlot, List<NoteEntry>> entriesBySlot;

  NutrientTotals totalFor(MealSlot slot) => NutrientTotals.of(entriesBySlot[slot]!.map((entry) => entry.nutrients));

  NutrientTotals get dayTotal =>
      NutrientTotals.of(entriesBySlot.values.expand((entries) => entries).map((entry) => entry.nutrients));

  // List.sort is not stable, so entries eaten at the same time need a tie-breaker to keep a fixed order.
  static int _byTimeThenId(NoteEntry first, NoteEntry second) {
    final byTime = first.eatenAt.compareTo(second.eatenAt);
    return byTime != 0 ? byTime : first.id.compareTo(second.id);
  }
}

/// Newest day first; days without entries are not included.
List<NoteDay> groupNoteEntries(Iterable<NoteEntry> entries) {
  final byDay = <CalendarDate, Map<MealSlot, List<NoteEntry>>>{};
  for (final entry in entries) {
    final (:day, :slot) = entry.placement;
    byDay.putIfAbsent(day, () => {}).putIfAbsent(slot, () => []).add(entry);
  }
  return [for (final MapEntry(key: date, value: slots) in byDay.entries) NoteDay._(date, slots)]
    ..sort((first, second) => second.date.compareTo(first.date));
}
