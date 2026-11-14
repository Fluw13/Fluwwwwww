import 'package:drift/drift.dart';

/// Added in schema v4. Nutrients are stored per 100 of [unit], copied from the source when the food was logged; a
/// NULL nutrient means the source had no data, never 0.
@DataClassName('NoteEntryRow')
class NoteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get sourceFoodId => text().nullable()();

  /// `g` or `ml`.
  TextColumn get unit => text()();
  RealColumn get quantity => real()();

  /// UTC milliseconds since epoch; the diary day and slot are worked out in local time when read.
  IntColumn get eatenAtUtcMs => integer()();

  RealColumn get energyKcal => real().nullable()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbohydratesG => real().nullable()();
  RealColumn get sugarsG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  RealColumn get saturatedFatG => real().nullable()();
  RealColumn get sodiumMg => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
