import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/features/note/domain/note_placement.dart';

final class NoteEntry {
  NoteEntry({
    required this.id,
    required this.name,
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
  final NutritionFacts facts;

  /// In the unit of [facts], so grams and millilitres cannot be mixed up.
  final double quantity;
  final DateTime eatenAt;

  Nutrients get nutrients => facts.forQuantity(quantity);

  NotePlacement get placement => placeInNote(eatenAt);
}
