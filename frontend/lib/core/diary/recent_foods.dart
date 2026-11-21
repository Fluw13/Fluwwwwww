import 'package:fluw/core/diary/note_entry.dart';

/// The newest entry of each different food, at most [limit], from entries given newest first. A food is the same when
/// it came from the same source id; foods without one are told apart by name and unit.
List<NoteEntry> distinctRecentFoods(Iterable<NoteEntry> newestFirst, {required int limit}) {
  final seen = <String>{};
  final foods = <NoteEntry>[];
  for (final entry in newestFirst) {
    if (foods.length >= limit) {
      break;
    }
    final key = entry.sourceFoodId ?? 'name:${entry.name.trim().toLowerCase()}:${entry.facts.unit.name}';
    if (seen.add(key)) {
      foods.add(entry);
    }
  }
  return List.unmodifiable(foods);
}
