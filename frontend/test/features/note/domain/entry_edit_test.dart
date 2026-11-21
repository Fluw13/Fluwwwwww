import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/domain/entry_edit.dart';

void main() {
  final entry = NoteEntry(
    id: 'a',
    name: 'Phở bò',
    sourceFoodId: 'off:1',
    facts: NutritionFacts(per100: Nutrients({Nutrient.energyKcal: 120}), unit: QuantityUnit.gram),
    quantity: 300,
    eatenAt: DateTime(2026, 11, 11, 7, 30),
  );
  final now = DateTime(2026, 11, 11, 19, 15);
  final day = CalendarDate(2026, 11, 11);

  test('chỉ đổi khẩu phần thì giữ nguyên giờ ăn, id, tên, số liệu', () {
    final edited = editNoteEntry(entry, quantity: 250, day: day, slot: MealSlot.morning, now: now);

    expect(edited.eatenAt, entry.eatenAt);
    expect(edited.quantity, 250);
    expect((edited.id, edited.name, edited.sourceFoodId, edited.facts), (entry.id, entry.name, 'off:1', entry.facts));
  });

  test('chuyển sang khung đang diễn ra thì lấy giờ thật, khung khác thì giờ cố định trong khung', () {
    expect(editNoteEntry(entry, quantity: 300, day: day, slot: MealSlot.evening, now: now).eatenAt, now);
    expect(
      editNoteEntry(entry, quantity: 300, day: day, slot: MealSlot.afternoon, now: now).eatenAt,
      DateTime(2026, 11, 11, 15),
    );
  });

  test('chuyển sang ngày khác cùng khung thì đổi ngày, giờ cố định của khung', () {
    final edited = editNoteEntry(
      entry,
      quantity: 300,
      day: CalendarDate(2026, 11, 10),
      slot: MealSlot.morning,
      now: now,
    );

    expect(edited.eatenAt, DateTime(2026, 11, 10, 9));
    expect(edited.placement, (day: CalendarDate(2026, 11, 10), slot: MealSlot.morning));
  });
}
