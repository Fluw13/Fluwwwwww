import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_time.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/time/calendar_date.dart';

/// [entry] with a new amount, moved to [day] and [slot]. Its time is kept while it stays where it was, so changing
/// only the amount never turns 07:30 into 09:00; a move takes the time [eatenAtFor] gives that slot.
NoteEntry editNoteEntry(
  NoteEntry entry, {
  required double quantity,
  required CalendarDate day,
  required MealSlot slot,
  required DateTime now,
}) {
  final placement = entry.placement;
  final stays = placement.day == day && placement.slot == slot;
  return NoteEntry(
    id: entry.id,
    name: entry.name,
    sourceFoodId: entry.sourceFoodId,
    facts: entry.facts,
    quantity: quantity,
    eatenAt: stays ? entry.eatenAt : eatenAtFor(day: day, slot: slot, now: now),
  );
}
