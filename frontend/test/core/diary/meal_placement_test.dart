import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/diary/meal_placement.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/time/calendar_date.dart';

void main() {
  final today = CalendarDate(2026, 11, 11);

  MealPlacement at(int hour, int minute, [int second = 0]) => placeMeal(DateTime(2026, 11, 11, hour, minute, second));

  const expectedSlots = {
    (6, 0): MealSlot.morning,
    (12, 0): MealSlot.morning,
    (12, 1): MealSlot.afternoon,
    (18, 0): MealSlot.afternoon,
    (18, 1): MealSlot.evening,
    (23, 59): MealSlot.evening,
    (0, 1): MealSlot.night,
    (5, 59): MealSlot.night,
  };

  for (final MapEntry(key: (hour, minute), value: slot) in expectedSlots.entries) {
    test('$hour:${minute.toString().padLeft(2, '0')} thuộc khung ${slot.name} của cùng ngày', () {
      expect(at(hour, minute), (day: today, slot: slot));
    });
  }

  test('bỏ qua giây: 12:00:59 vẫn là Sáng, 05:59:59 vẫn là Đêm', () {
    expect(at(12, 0, 59).slot, MealSlot.morning);
    expect(at(5, 59, 59), (day: today, slot: MealSlot.night));
  });

  test('bỏ qua giây ở mốc 00:00: 00:00:59 vẫn thuộc Tối hôm trước', () {
    expect(at(0, 0, 59), (day: CalendarDate(2026, 11, 10), slot: MealSlot.evening));
  });

  test('giờ dạng UTC được đổi về giờ địa phương trước khi xếp', () {
    for (final local in [DateTime(2026, 11, 12), DateTime(2026, 11, 11, 6), DateTime(2026, 11, 11, 23, 59)]) {
      expect(placeMeal(local.toUtc()), placeMeal(local));
    }
  });

  test('00:00 là 24:00, thuộc khung Tối của ngày hôm trước', () {
    expect(at(0, 0), (day: CalendarDate(2026, 11, 10), slot: MealSlot.evening));
  });

  test('00:00 ngày 1/1 thuộc Tối 31/12 năm trước; 00:00 ngày 1/3/2028 thuộc Tối 29/2', () {
    expect(placeMeal(DateTime(2027, 1, 1)), (day: CalendarDate(2026, 12, 31), slot: MealSlot.evening));
    expect(placeMeal(DateTime(2028, 3, 1)), (day: CalendarDate(2028, 2, 29), slot: MealSlot.evening));
  });

  test('thứ tự khung trong một ngày: Đêm, Sáng, Chiều, Tối', () {
    expect(MealSlot.values, [MealSlot.night, MealSlot.morning, MealSlot.afternoon, MealSlot.evening]);
  });
}
