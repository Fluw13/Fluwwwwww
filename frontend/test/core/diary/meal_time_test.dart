import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/diary/meal_placement.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/meal_time.dart';
import 'package:fluw/core/time/calendar_date.dart';

void main() {
  final day = CalendarDate(2026, 11, 11);

  test('thêm vào đúng khung đang diễn ra thì giữ giờ thật', () {
    final now = DateTime(2026, 11, 11, 12, 45, 30);

    expect(eatenAtFor(day: day, slot: MealSlot.afternoon, now: now), now);
  });

  test('thêm vào khung khác thì dùng giờ cố định nằm trong khung đó, đúng ngày đã chọn', () {
    final now = DateTime(2026, 11, 11, 12, 45);

    for (final slot in MealSlot.values) {
      if (slot == MealSlot.afternoon) continue;
      final eatenAt = eatenAtFor(day: day, slot: slot, now: now);
      expect(placeMeal(eatenAt), (day: day, slot: slot), reason: '$slot');
    }
  });

  test('lúc 00:00 (thuộc Tối hôm trước) chọn Đêm hôm nay thì vào Đêm hôm nay, không giữ giờ 00:00', () {
    final now = DateTime(2026, 11, 12);
    final today = CalendarDate(2026, 11, 12);

    final eatenAt = eatenAtFor(day: today, slot: MealSlot.night, now: now);

    expect(placeMeal(eatenAt), (day: today, slot: MealSlot.night));
  });

  test('thứ tự hiển thị theo thiết kế, tên khung luôn kèm giờ', () {
    expect(mealSlotDisplayOrder, [MealSlot.morning, MealSlot.afternoon, MealSlot.evening, MealSlot.night]);
    expect(mealSlotDisplayOrder.map(mealSlotLabel), ['Sáng', 'Trưa / Chiều', 'Tối', 'Khuya / Đêm']);
    expect(mealSlotHours(MealSlot.night), '00:01 - 05:59');
    expect(mealSlotHours(MealSlot.evening), '18:01 - 24:00');
  });
}
