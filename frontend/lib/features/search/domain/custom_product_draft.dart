import 'package:collection/collection.dart';
import 'package:fluw/core/barcode/gtin.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/portion_limits.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/custom_product.dart';

const int maxProductNameLength = 100;

/// The largest amounts per 100 g or ml a food can have, the same as the backend's: pure fat is about 900 kcal, pure
/// salt about 39,300 mg sodium.
double maxPer100(Nutrient nutrient) => switch (nutrient) {
  Nutrient.energyKcal => 900,
  Nutrient.sodiumMg => 40000,
  _ => 100,
};

enum CustomProductField { name, brand, barcode, servingAmount, packageAmount, nutrient }

enum CustomProductIssue {
  required,
  tooLong,
  barcodeLength,
  barcodeCheckDigit,
  invalidNumber,
  portionOutOfRange,
  tooHighPer100,
  sugarsAboveCarbohydrates,
  saturatedFatAboveFat,
}

sealed class CustomProductResult {
  const CustomProductResult();
}

final class ValidCustomProduct extends CustomProductResult {
  const ValidCustomProduct(this.product);

  final CustomProduct product;
}

final class InvalidCustomProduct extends CustomProductResult {
  InvalidCustomProduct({required Map<CustomProductField, CustomProductIssue> fields, required this.nutrients})
    : fields = Map.unmodifiable(fields);

  /// Issues of the fields other than the nutrients.
  final Map<CustomProductField, CustomProductIssue> fields;
  final Map<Nutrient, CustomProductIssue> nutrients;
}

/// What the user typed in the label form, as text. [nutrients] are as printed: per 100 or, when [labelPerServing],
/// per serving of [servingAmount]; a blank one means the label has no number for it.
final class CustomProductDraft {
  const CustomProductDraft({
    this.name = '',
    this.brand = '',
    this.barcode = '',
    this.unit = QuantityUnit.gram,
    this.labelPerServing = false,
    this.servingAmount = '',
    this.packageAmount = '',
    this.nutrients = const {},
  });

  /// The numbers come back the way the label printed them; per serving they are rounded to 2 decimals, so 114 kcal
  /// stored as 25.909… per 100 ml shows as 114 again.
  factory CustomProductDraft.fromProduct(CustomProduct product) {
    final serving = product.servingAmount;
    final factor = product.labelPerServing && serving != null ? serving / 100 : 1.0;
    String text(double? value) => value == null ? '' : formatDecimal(value, maxFractionDigits: 2);
    return CustomProductDraft(
      name: product.name,
      brand: product.brand ?? '',
      barcode: product.barcode ?? '',
      unit: product.facts.unit,
      labelPerServing: product.labelPerServing && serving != null,
      servingAmount: text(serving),
      packageAmount: text(product.packageAmount),
      nutrients: {
        for (final nutrient in Nutrient.values)
          if (product.facts.per100[nutrient] case final value?) nutrient: text(value * factor),
      },
    );
  }

  final String name;
  final String brand;
  final String barcode;
  final QuantityUnit unit;
  final bool labelPerServing;
  final String servingAmount;
  final String packageAmount;
  final Map<Nutrient, String> nutrients;

  String nutrientText(Nutrient nutrient) => nutrients[nutrient] ?? '';

  CustomProductResult build({required String id}) {
    final fields = <CustomProductField, CustomProductIssue>{};
    final nutrientIssues = <Nutrient, CustomProductIssue>{};

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      fields[CustomProductField.name] = CustomProductIssue.required;
    } else if (trimmedName.length > maxProductNameLength) {
      fields[CustomProductField.name] = CustomProductIssue.tooLong;
    }
    final trimmedBrand = brand.trim();
    if (trimmedBrand.length > maxProductNameLength) {
      fields[CustomProductField.brand] = CustomProductIssue.tooLong;
    }
    final code = barcode.trim();
    if (code.isNotEmpty && !hasGtinLength(code)) {
      fields[CustomProductField.barcode] = CustomProductIssue.barcodeLength;
    } else if (code.isNotEmpty && !isValidGtin(code)) {
      fields[CustomProductField.barcode] = CustomProductIssue.barcodeCheckDigit;
    }

    double? amount(String text, CustomProductField field, {required bool isRequired}) {
      if (text.trim().isEmpty) {
        if (isRequired) {
          fields[field] = CustomProductIssue.required;
        }
        return null;
      }
      final value = parseDecimal(text);
      if (value == null) {
        fields[field] = CustomProductIssue.invalidNumber;
      } else if (!isValidPortion(value)) {
        fields[field] = CustomProductIssue.portionOutOfRange;
      } else {
        return value;
      }
      return null;
    }

    final serving = amount(servingAmount, CustomProductField.servingAmount, isRequired: labelPerServing);
    final package = amount(packageAmount, CustomProductField.packageAmount, isRequired: false);

    // Per serving without a valid serving the numbers cannot be turned into per 100, so only their form is checked.
    final factor = labelPerServing ? (serving == null ? null : 100 / serving) : 1.0;
    final per100 = <Nutrient, double>{};
    for (final nutrient in Nutrient.values) {
      final text = nutrientText(nutrient).trim();
      if (text.isEmpty) {
        if (nutrient == Nutrient.energyKcal) {
          nutrientIssues[nutrient] = CustomProductIssue.required;
        }
        continue;
      }
      final value = parseDecimal(text);
      if (value == null) {
        nutrientIssues[nutrient] = CustomProductIssue.invalidNumber;
      } else if (factor != null) {
        final perHundred = value * factor;
        if (perHundred > maxPer100(nutrient)) {
          nutrientIssues[nutrient] = CustomProductIssue.tooHighPer100;
        } else {
          per100[nutrient] = perHundred;
        }
      }
    }
    if (per100[Nutrient.sugarsG] case final sugars? when sugars > (per100[Nutrient.carbohydratesG] ?? sugars)) {
      nutrientIssues[Nutrient.sugarsG] = CustomProductIssue.sugarsAboveCarbohydrates;
    }
    if (per100[Nutrient.saturatedFatG] case final saturated? when saturated > (per100[Nutrient.fatG] ?? saturated)) {
      nutrientIssues[Nutrient.saturatedFatG] = CustomProductIssue.saturatedFatAboveFat;
    }

    if (fields.isNotEmpty || nutrientIssues.isNotEmpty) {
      return InvalidCustomProduct(fields: fields, nutrients: Map.unmodifiable(nutrientIssues));
    }
    return ValidCustomProduct(
      CustomProduct(
        id: id,
        name: trimmedName,
        brand: trimmedBrand.isEmpty ? null : trimmedBrand,
        barcode: code.isEmpty ? null : code,
        facts: NutritionFacts(per100: Nutrients(per100), unit: unit),
        packageAmount: package,
        servingAmount: serving,
        labelPerServing: labelPerServing,
      ),
    );
  }

  static const MapEquality<Nutrient, String> _nutrientsEquality = MapEquality();

  /// Blank nutrients count as missing, so clearing a field the draft never had is not a change.
  Map<Nutrient, String> get _filledNutrients => {
    for (final MapEntry(:key, :value) in nutrients.entries)
      if (value.trim().isNotEmpty) key: value.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is CustomProductDraft &&
      other.name.trim() == name.trim() &&
      other.brand.trim() == brand.trim() &&
      other.barcode.trim() == barcode.trim() &&
      other.unit == unit &&
      other.labelPerServing == labelPerServing &&
      other.servingAmount.trim() == servingAmount.trim() &&
      other.packageAmount.trim() == packageAmount.trim() &&
      _nutrientsEquality.equals(other._filledNutrients, _filledNutrients);

  @override
  int get hashCode => Object.hash(
    name.trim(),
    brand.trim(),
    barcode.trim(),
    unit,
    labelPerServing,
    servingAmount.trim(),
    packageAmount.trim(),
    _nutrientsEquality.hash(_filledNutrients),
  );
}
