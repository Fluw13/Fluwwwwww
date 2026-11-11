import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/domain/meal_slot.dart';
import 'package:fluw/features/note/domain/note_day.dart';
import 'package:fluw/features/note/domain/note_entry.dart';

NoteEntry _entry(
  String name,
  DateTime eatenAt, {
  String? id,
  double kcalPer100 = 100,
  double? proteinPer100,
  double quantity = 100,
}) {
  return NoteEntry(
    id: id ?? name,
    name: name,
    facts: NutritionFacts(
      per100: Nutrients({Nutrient.energyKcal: kcalPer100, Nutrient.proteinG: ?proteinPer100}),
      unit: QuantityUnit.gram,
    ),
    quantity: quantity,
    eatenAt: eatenAt,
  );
}

void main() {
  test('lượng dinh dưỡng của món = số liệu cho 100 × khối lượng / 100', () {
    final rice = _entry('Cơm', DateTime(2026, 11, 11, 12, 30), kcalPer100: 130, proteinPer100: 2.7, quantity: 200);

    expect(rice.nutrients[Nutrient.energyKcal], closeTo(260, 1e-9));
    expect(rice.nutrients[Nutrient.proteinG], closeTo(5.4, 1e-9));
  });

  test('khối lượng phải lớn hơn 0', () {
    expect(() => _entry('Lỗi', DateTime(2026, 11, 11), quantity: 0), throwsArgumentError);
    expect(() => _entry('Lỗi', DateTime(2026, 11, 11), quantity: -50), throwsArgumentError);
  });

  group('gom món theo ngày và khung giờ', () {
    final days = groupNoteEntries([
      _entry('Bánh mì', DateTime(2026, 11, 11, 7, 30), kcalPer100: 250, proteinPer100: 9),
      _entry('Phở', DateTime(2026, 11, 11, 12, 30), kcalPer100: 120, proteinPer100: 6, quantity: 500),
      _entry('Sữa', DateTime(2026, 11, 11, 6, 15), kcalPer100: 60, quantity: 200),
      _entry('Mì gói', DateTime(2026, 11, 12, 0, 0), kcalPer100: 450, proteinPer100: 10),
      _entry('Bánh quy', DateTime(2026, 11, 12, 1, 30), kcalPer100: 480, proteinPer100: 6),
    ]);

    test('ngày mới nhất đứng đầu; món lúc 00:00 ngày 12 thuộc Tối ngày 11', () {
      expect(days.map((day) => day.date), [CalendarDate(2026, 11, 12), CalendarDate(2026, 11, 11)]);
      expect(days[1].entriesBySlot[MealSlot.evening]!.single.name, 'Mì gói');
      expect(days[0].entriesBySlot[MealSlot.night]!.single.name, 'Bánh quy');
    });

    test('món trong cùng khung xếp theo giờ ăn', () {
      expect(days[1].entriesBySlot[MealSlot.morning]!.map((entry) => entry.name), ['Sữa', 'Bánh mì']);
    });

    test('khung không có món thì là danh sách rỗng và tổng bằng 0', () {
      expect(days[1].entriesBySlot[MealSlot.night], isEmpty);
      expect(days[1].totalFor(MealSlot.night)[Nutrient.energyKcal].knownSum, 0);
    });

    test('tổng theo khung và theo ngày, có đếm món thiếu protein', () {
      final day11 = days[1];

      expect(day11.totalFor(MealSlot.morning)[Nutrient.energyKcal].knownSum, closeTo(370, 1e-9));
      expect(day11.totalFor(MealSlot.morning)[Nutrient.proteinG].knownSum, closeTo(9, 1e-9));
      expect(day11.totalFor(MealSlot.morning)[Nutrient.proteinG].missingCount, 1);
      expect(day11.dayTotal[Nutrient.energyKcal].knownSum, closeTo(1420, 1e-9));
      expect(day11.dayTotal[Nutrient.proteinG].knownSum, closeTo(49, 1e-9));
      expect(day11.dayTotal[Nutrient.proteinG].missingCount, 1);
    });

    test('tổng ngày tính cả khung Đêm', () {
      expect(days[0].dayTotal[Nutrient.energyKcal].knownSum, closeTo(480, 1e-9));
    });

    test('danh sách món và bảng khung giờ không sửa được từ bên ngoài', () {
      expect(() => days[0].entriesBySlot[MealSlot.night]!.clear(), throwsUnsupportedError);
      expect(() => days[0].entriesBySlot.remove(MealSlot.night), throwsUnsupportedError);
    });
  });

  test('nhiều món cùng một phút giữ thứ tự cố định theo id', () {
    final sameMinute = DateTime(2026, 11, 11, 7);
    final ids = [for (var index = 0; index < 40; index++) 'x${index.toString().padLeft(2, '0')}'];

    final days = groupNoteEntries([for (final id in ids.reversed) _entry(id, sameMinute, id: id)]);

    expect(days.single.entriesBySlot[MealSlot.morning]!.map((entry) => entry.id), ids);
  });

  test('không có món nào thì không có ngày nào', () {
    expect(groupNoteEntries(const []), isEmpty);
  });
}
