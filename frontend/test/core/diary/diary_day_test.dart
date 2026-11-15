import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/diary/diary_day.dart';
import 'package:fluw/core/diary/diary_reader.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/data/note_repository.dart';

import '../../helpers/in_memory_database.dart';

NoteEntry _entry(String id, DateTime eatenAt) => NoteEntry(
  id: id,
  name: id,
  sourceFoodId: null,
  facts: NutritionFacts(per100: Nutrients(const {Nutrient.energyKcal: 100}), unit: QuantityUnit.gram),
  quantity: 100,
  eatenAt: eatenAt,
);

/// The provider is autoDispose: keep it listened until its first value arrives.
Future<DiaryDay> _read(ProviderContainer container, CalendarDate date) async {
  final first = Completer<DiaryDay>();
  final subscription = container.listen<AsyncValue<DiaryDay>>(diaryDayProvider(date), (_, next) {
    if (next case AsyncData(:final value) when !first.isCompleted) {
      first.complete(value);
    }
  }, fireImmediately: true);
  try {
    return await first.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}

void main() {
  late AppDatabase database;
  late NoteRepository repository;
  late ProviderContainer container;

  setUp(() {
    database = openInMemoryDatabase();
    repository = NoteRepository(database);
    container = ProviderContainer(overrides: [diaryReaderProvider.overrideWithValue(repository)]);
  });
  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test(
    'một ngày Nhật ký: 00:00 thuộc Tối hôm trước, 00:00:59 hôm sau vẫn là Tối của ngày này, 00:01 thì không',
    () async {
      for (final entry in [
        _entry('previous-evening', DateTime(2026, 11, 11, 0, 0, 30)),
        _entry('night', DateTime(2026, 11, 11, 0, 1)),
        _entry('evening-end', DateTime(2026, 11, 12, 0, 0, 59)),
        _entry('next-night', DateTime(2026, 11, 12, 0, 1)),
      ]) {
        await repository.add(entry);
      }

      final day = await _read(container, CalendarDate(2026, 11, 11));

      expect(day.entryCount, 2);
      expect(day.day!.entriesBySlot[MealSlot.night]!.map((entry) => entry.id), ['night']);
      expect(day.day!.entriesBySlot[MealSlot.evening]!.map((entry) => entry.id), ['evening-end']);
    },
  );

  test('ngày chưa ghi món: không có NoteDay, 0 món, kể cả khi có món 00:00 thuộc hôm trước', () async {
    await repository.add(_entry('previous-evening', DateTime(2026, 11, 11, 0, 0, 30)));

    final day = await _read(container, CalendarDate(2026, 11, 11));

    expect(day.day, isNull);
    expect(day.entryCount, 0);
  });
}
