import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/note/domain/note_entry.dart';

/// Fixed storage keys; never rename, only add.
const Map<QuantityUnit, String> quantityUnitKeys = {QuantityUnit.gram: 'g', QuantityUnit.milliliter: 'ml'};

NoteEntriesCompanion noteEntryToRow(NoteEntry entry) {
  final per100 = entry.facts.per100;
  return NoteEntriesCompanion.insert(
    id: entry.id,
    name: entry.name,
    sourceFoodId: Value(entry.sourceFoodId),
    unit: quantityUnitKeys[entry.facts.unit]!,
    quantity: entry.quantity,
    eatenAtUtcMs: entry.eatenAt.toUtc().millisecondsSinceEpoch,
    energyKcal: Value(per100[Nutrient.energyKcal]),
    proteinG: Value(per100[Nutrient.proteinG]),
    carbohydratesG: Value(per100[Nutrient.carbohydratesG]),
    sugarsG: Value(per100[Nutrient.sugarsG]),
    fatG: Value(per100[Nutrient.fatG]),
    saturatedFatG: Value(per100[Nutrient.saturatedFatG]),
    sodiumMg: Value(per100[Nutrient.sodiumMg]),
  );
}

/// Returns null for a row this version cannot read (unknown unit, impossible numbers), so one bad row is left out
/// instead of breaking the whole diary.
NoteEntry? noteEntryFromRow(NoteEntryRow row) {
  final unit = quantityUnitKeys.entries.where((entry) => entry.value == row.unit).firstOrNull?.key;
  final values = <Nutrient, double?>{
    Nutrient.energyKcal: row.energyKcal,
    Nutrient.proteinG: row.proteinG,
    Nutrient.carbohydratesG: row.carbohydratesG,
    Nutrient.sugarsG: row.sugarsG,
    Nutrient.fatG: row.fatG,
    Nutrient.saturatedFatG: row.saturatedFatG,
    Nutrient.sodiumMg: row.sodiumMg,
  };
  if (unit == null || !row.quantity.isFinite || row.quantity <= 0) {
    return null;
  }
  try {
    return NoteEntry(
      id: row.id,
      name: row.name,
      sourceFoodId: row.sourceFoodId,
      facts: NutritionFacts(
        per100: Nutrients({for (final MapEntry(key: nutrient, :value) in values.entries) nutrient: ?value}),
        unit: unit,
      ),
      quantity: row.quantity,
      eatenAt: DateTime.fromMillisecondsSinceEpoch(row.eatenAtUtcMs, isUtc: true),
    );
  } on ArgumentError {
    return null;
  }
}
