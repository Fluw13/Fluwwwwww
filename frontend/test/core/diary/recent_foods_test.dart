import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/diary/recent_foods.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';

NoteEntry _entry(String id, {String? sourceFoodId, String name = 'Món', QuantityUnit unit = QuantityUnit.gram}) =>
    NoteEntry(
      id: id,
      name: name,
      sourceFoodId: sourceFoodId,
      facts: NutritionFacts(per100: Nutrients(const {}), unit: unit),
      quantity: 100,
      eatenAt: DateTime(2026, 11, 11),
    );

void main() {
  test('mỗi món một lần, giữ lần mới nhất, theo thứ tự đưa vào (mới nhất trước)', () {
    final foods = distinctRecentFoods([
      _entry('3', sourceFoodId: 'off:1'),
      _entry('2', sourceFoodId: 'usda:2'),
      _entry('1', sourceFoodId: 'off:1'),
    ], limit: 10);

    expect(foods.map((food) => food.id), ['3', '2']);
  });

  test('món không có id nguồn thì so theo tên (không phân biệt hoa thường, dấu cách đầu cuối) và đơn vị', () {
    final foods = distinctRecentFoods([
      _entry('4', name: 'Cơm nhà'),
      _entry('3', name: ' cơm nhà '),
      _entry('2', name: 'Cơm nhà', unit: QuantityUnit.milliliter),
      _entry('1', name: 'Cơm nhà', sourceFoodId: 'off:9'),
    ], limit: 10);

    expect(foods.map((food) => food.id), ['4', '2', '1']);
  });

  test('dừng ở số món tối đa', () {
    final foods = distinctRecentFoods([
      for (var index = 0; index < 20; index++) _entry('$index', name: 'Món $index'),
    ], limit: 8);

    expect(foods, hasLength(8));
    expect(foods.last.id, '7');
  });
}
