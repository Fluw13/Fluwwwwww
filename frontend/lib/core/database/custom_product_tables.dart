import 'package:drift/drift.dart';

/// Added in schema v6: products the user typed in from a label. Nutrients are stored per 100 of [unit]; a NULL
/// nutrient means the label had no number for it, never 0.
@DataClassName('CustomProductRow')
class CustomProducts extends Table {
  TextColumn get id => text()();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();

  /// `g` or `ml`.
  TextColumn get unit => text()();
  RealColumn get packageAmount => real().nullable()();
  RealColumn get servingAmount => real().nullable()();

  /// True when the label gave the numbers for one serving; the form shows them that way again when editing.
  BoolColumn get labelPerServing => boolean()();

  RealColumn get energyKcal => real().nullable()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbohydratesG => real().nullable()();
  RealColumn get sugarsG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  RealColumn get saturatedFatG => real().nullable()();
  RealColumn get sodiumMg => real().nullable()();

  /// UTC milliseconds since epoch.
  IntColumn get updatedAtUtcMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
