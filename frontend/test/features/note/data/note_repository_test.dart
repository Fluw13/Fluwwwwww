import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/diary/logged_food.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/note/data/note_entry_mapper.dart';
import 'package:fluw/features/note/data/note_food_logger.dart';
import 'package:fluw/features/note/data/note_id.dart';
import 'package:fluw/features/note/data/note_repository.dart';
import 'package:fluw/features/note/domain/note_entry.dart';

import '../../../helpers/in_memory_database.dart';

NoteEntry _entry(String id, DateTime eatenAt, {QuantityUnit unit = QuantityUnit.gram, double quantity = 150}) {
  return NoteEntry(
    id: id,
    name: 'Sữa chua $id',
    sourceFoodId: 'off:8934673573123',
    facts: NutritionFacts(
      per100: Nutrients({Nutrient.energyKcal: 99.5, Nutrient.sugarsG: 0, Nutrient.sodiumMg: 45}),
      unit: unit,
    ),
    quantity: quantity,
    eatenAt: eatenAt,
  );
}

void main() {
  late AppDatabase database;
  late NoteRepository repository;

  setUp(() {
    database = openInMemoryDatabase();
    repository = NoteRepository(database);
  });
  tearDown(() => database.close());

  test('lưu rồi đọc lại đúng món: thiếu số liệu vẫn là thiếu, 0 vẫn là 0, đơn vị ml giữ nguyên', () async {
    final entry = _entry('a', DateTime.utc(2026, 11, 11, 5, 30), unit: QuantityUnit.milliliter, quantity: 330);

    await repository.add(entry);
    final stored = await repository.watchBetween(DateTime.utc(2026, 11, 11), DateTime.utc(2026, 11, 12)).first;

    expect(stored, [entry]);
    expect(stored.single.facts.per100[Nutrient.proteinG], isNull);
    expect(stored.single.facts.per100[Nutrient.sugarsG], 0);
    expect(stored.single.facts.unit, QuantityUnit.milliliter);
  });

  test('chỉ đọc món trong khoảng [from, to), xếp theo giờ ăn', () async {
    await repository.add(_entry('late', DateTime.utc(2026, 11, 11, 23)));
    await repository.add(_entry('early', DateTime.utc(2026, 11, 11, 1)));
    await repository.add(_entry('edge', DateTime.utc(2026, 11, 12)));
    await repository.add(_entry('before', DateTime.utc(2026, 11, 10, 23, 59)));

    final stored = await repository.watchBetween(DateTime.utc(2026, 11, 11), DateTime.utc(2026, 11, 12)).first;

    expect(stored.map((entry) => entry.id), ['early', 'late']);
  });

  test('watch phát lại khi thêm và xóa món', () async {
    final stream = repository.watchBetween(DateTime.utc(2026, 11, 11), DateTime.utc(2026, 11, 12));
    final emitted = <List<String>>[];
    final subscription = stream.listen((entries) => emitted.add([for (final entry in entries) entry.id]));
    await pumpEventQueue();

    await repository.add(_entry('a', DateTime.utc(2026, 11, 11, 8)));
    await pumpEventQueue();
    await repository.delete('a');
    await pumpEventQueue();
    await subscription.cancel();

    expect(emitted, [
      <String>[],
      ['a'],
      <String>[],
    ]);
  });

  test('dòng hỏng (đơn vị lạ, khối lượng 0, số âm) bị bỏ riêng, các món khác vẫn đọc được', () async {
    await repository.add(_entry('ok', DateTime.utc(2026, 11, 11, 8)));
    for (final (id, unit, quantity, kcal) in [
      ('unit', 'oz', 100.0, 50.0),
      ('zero', 'g', 0.0, 50.0),
      ('neg', 'g', 100.0, -1.0),
    ]) {
      await database
          .into(database.noteEntries)
          .insert(
            NoteEntriesCompanion.insert(
              id: id,
              name: id,
              unit: unit,
              quantity: quantity,
              eatenAtUtcMs: DateTime.utc(2026, 11, 11, 9).millisecondsSinceEpoch,
              energyKcal: Value(kcal),
            ),
          );
    }

    final stored = await repository.watchBetween(DateTime.utc(2026, 11, 11), DateTime.utc(2026, 11, 12)).first;

    expect(stored.map((entry) => entry.id), ['ok']);
  });

  test('khóa đơn vị lưu cố định, không bao giờ đổi', () {
    expect(quantityUnitKeys, {QuantityUnit.gram: 'g', QuantityUnit.milliliter: 'ml'});
  });

  test('NoteFoodLogger lưu món từ tính năng khác thành một món Nhật ký có id mới', () async {
    final logger = NoteFoodLogger(repository);
    final facts = NutritionFacts(per100: Nutrients({Nutrient.energyKcal: 42.25}), unit: QuantityUnit.milliliter);

    for (var count = 0; count < 2; count++) {
      await logger.log(
        LoggedFood(
          name: 'Coca-Cola',
          sourceFoodId: 'off:5449000000996',
          facts: facts,
          quantity: 330,
          eatenAt: DateTime.utc(2026, 11, 11, 7),
        ),
      );
    }
    final stored = await repository.watchBetween(DateTime.utc(2026, 11, 11), DateTime.utc(2026, 11, 12)).first;

    expect(stored, hasLength(2));
    expect(stored.map((entry) => entry.id).toSet(), hasLength(2));
    expect(stored.first.name, 'Coca-Cola');
    expect(stored.first.sourceFoodId, 'off:5449000000996');
    expect(stored.first.nutrients[Nutrient.energyKcal], closeTo(139.425, 1e-9));
  });

  test('id sinh ra không trùng và tăng theo thời gian', () {
    final ids = {for (var index = 0; index < 1000; index++) newNoteEntryId(now: DateTime.utc(2026, 11, 11))};
    expect(ids, hasLength(1000));
    expect(
      newNoteEntryId(now: DateTime.utc(2026, 11, 11)).compareTo(newNoteEntryId(now: DateTime.utc(2026, 11, 12))),
      lessThan(0),
    );
  });

  test('LoggedFood từ chối khối lượng 0, âm hoặc không hữu hạn', () {
    final facts = NutritionFacts(per100: Nutrients(const {}), unit: QuantityUnit.gram);
    for (final quantity in [0.0, -1.0, double.nan]) {
      expect(
        () => LoggedFood(name: 'x', sourceFoodId: null, facts: facts, quantity: quantity, eatenAt: DateTime(2026)),
        throwsArgumentError,
      );
    }
  });
}
