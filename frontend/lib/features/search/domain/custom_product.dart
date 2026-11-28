import 'package:fluw/core/nutrition/nutrition_facts.dart';

/// A product the user typed in from its label. [facts] are always per 100 of their unit; [labelPerServing] only
/// remembers how the label printed them, so the form can show them the same way when editing.
final class CustomProduct {
  const CustomProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.facts,
    required this.packageAmount,
    required this.servingAmount,
    required this.labelPerServing,
  });

  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final NutritionFacts facts;

  /// The whole pack or bottle, in the unit of [facts].
  final double? packageAmount;

  /// One serving as printed on the label, in the unit of [facts].
  final double? servingAmount;

  final bool labelPerServing;

  @override
  bool operator ==(Object other) =>
      other is CustomProduct &&
      other.id == id &&
      other.name == name &&
      other.brand == brand &&
      other.barcode == barcode &&
      other.facts == facts &&
      other.packageAmount == packageAmount &&
      other.servingAmount == servingAmount &&
      other.labelPerServing == labelPerServing;

  @override
  int get hashCode => Object.hash(id, name, brand, barcode, facts, packageAmount, servingAmount, labelPerServing);
}
