import 'package:fluw/core/diary/meal_placement.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';

final class NoteEntry {
  NoteEntry({
    required this.id,
    required this.name,
    required this.sourceFoodId,
    required this.facts,
    required this.quantity,
    required this.eatenAt,
  }) {
    if (!quantity.isFinite || quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Phải lớn hơn 0');
    }
  }

  final String id;
  final String name;

  /// The backend id the food came from, if any; kept for reference only.
  final String? sourceFoodId;
  final NutritionFacts facts;

  /// In the unit of [facts], so grams and millilitres cannot be mixed up.
  final double quantity;
  final DateTime eatenAt;

  Nutrients get nutrients => facts.forQuantity(quantity);

  MealPlacement get placement => placeMeal(eatenAt);

  @override
  bool operator ==(Object other) =>
      other is NoteEntry &&
      other.id == id &&
      other.name == name &&
      other.sourceFoodId == sourceFoodId &&
      other.facts == facts &&
      other.quantity == quantity &&
      other.eatenAt.isAtSameMomentAs(eatenAt);

  @override
  int get hashCode => Object.hash(id, name, sourceFoodId, facts, quantity, eatenAt.microsecondsSinceEpoch);
}
