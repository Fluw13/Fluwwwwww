import 'package:fluw/core/diary/food_logger.dart';
import 'package:fluw/core/diary/logged_food.dart';
import 'package:fluw/features/note/data/note_id.dart';
import 'package:fluw/features/note/data/note_repository.dart';
import 'package:fluw/features/note/domain/note_entry.dart';

/// The diary's side of [FoodLogger]: turns a food from any feature into a stored diary entry.
final class NoteFoodLogger implements FoodLogger {
  NoteFoodLogger(this._repository);

  final NoteRepository _repository;

  @override
  Future<void> log(LoggedFood food) => _repository.add(
    NoteEntry(
      id: newNoteEntryId(),
      name: food.name,
      sourceFoodId: food.sourceFoodId,
      facts: food.facts,
      quantity: food.quantity,
      eatenAt: food.eatenAt,
    ),
  );
}
