import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/features/note/domain/note_placement.dart';

enum QuantityUnit { gram, milliliter }

final class NoteEntry {
  NoteEntry({
    required this.name,
    required this.nutrientsPer100,
    required this.quantity,
    required this.unit,
    required this.eatenAt,
  }) {
    if (!quantity.isFinite || quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Phải lớn hơn 0');
    }
  }

  final String name;
  final Nutrients nutrientsPer100;
  final double quantity;
  final QuantityUnit unit;
  final DateTime eatenAt;

  Nutrients get nutrients => nutrientsPer100.scaled(quantity / 100);

  NotePlacement get placement => placeInNote(eatenAt);
}
