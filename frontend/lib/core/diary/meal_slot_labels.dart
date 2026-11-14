import 'package:fluw/core/diary/meal_slot.dart';

/// The design's order: Khuya/Đêm comes last on screen although it is the first slot of the day (CLAUDE.md).
const List<MealSlot> mealSlotDisplayOrder = [MealSlot.morning, MealSlot.afternoon, MealSlot.evening, MealSlot.night];

String mealSlotLabel(MealSlot slot) => switch (slot) {
  MealSlot.morning => 'Sáng',
  MealSlot.afternoon => 'Trưa / Chiều',
  MealSlot.evening => 'Tối',
  MealSlot.night => 'Khuya / Đêm',
};

/// Always shown next to the name, so "Khuya" is never read as "after Tối".
String mealSlotHours(MealSlot slot) => switch (slot) {
  MealSlot.morning => '06:00 - 12:00',
  MealSlot.afternoon => '12:01 - 18:00',
  MealSlot.evening => '18:01 - 24:00',
  MealSlot.night => '00:01 - 05:59',
};
