import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/custom_product.dart';

/// Fixed storage keys, the same as the diary's; never rename, only add.
const Map<QuantityUnit, String> _unitKeys = {QuantityUnit.gram: 'g', QuantityUnit.milliliter: 'ml'};

CustomProductsCompanion customProductToRow(CustomProduct product, {required DateTime updatedAt}) {
  final per100 = product.facts.per100;
  return CustomProductsCompanion.insert(
    id: product.id,
    barcode: Value(product.barcode),
    name: product.name,
    brand: Value(product.brand),
    unit: _unitKeys[product.facts.unit]!,
    packageAmount: Value(product.packageAmount),
    servingAmount: Value(product.servingAmount),
    labelPerServing: product.labelPerServing,
    energyKcal: Value(per100[Nutrient.energyKcal]),
    proteinG: Value(per100[Nutrient.proteinG]),
    carbohydratesG: Value(per100[Nutrient.carbohydratesG]),
    sugarsG: Value(per100[Nutrient.sugarsG]),
    fatG: Value(per100[Nutrient.fatG]),
    saturatedFatG: Value(per100[Nutrient.saturatedFatG]),
    sodiumMg: Value(per100[Nutrient.sodiumMg]),
    updatedAtUtcMs: updatedAt.toUtc().millisecondsSinceEpoch,
  );
}

/// Null for a row this version cannot read (unknown unit, impossible numbers), so one bad row is left out instead of
/// breaking every lookup.
CustomProduct? customProductFromRow(CustomProductRow row) {
  final unit = _unitKeys.entries.where((entry) => entry.value == row.unit).firstOrNull?.key;
  final values = <Nutrient, double?>{
    Nutrient.energyKcal: row.energyKcal,
    Nutrient.proteinG: row.proteinG,
    Nutrient.carbohydratesG: row.carbohydratesG,
    Nutrient.sugarsG: row.sugarsG,
    Nutrient.fatG: row.fatG,
    Nutrient.saturatedFatG: row.saturatedFatG,
    Nutrient.sodiumMg: row.sodiumMg,
  };
  bool isAmount(double? value) => value == null || (value.isFinite && value > 0);
  if (unit == null || !isAmount(row.packageAmount) || !isAmount(row.servingAmount)) {
    return null;
  }
  try {
    return CustomProduct(
      id: row.id,
      name: row.name,
      brand: row.brand,
      barcode: row.barcode,
      facts: NutritionFacts(
        per100: Nutrients({for (final MapEntry(key: nutrient, :value) in values.entries) nutrient: ?value}),
        unit: unit,
      ),
      packageAmount: row.packageAmount,
      servingAmount: row.servingAmount,
      labelPerServing: row.labelPerServing,
    );
  } on ArgumentError {
    return null;
  }
}
