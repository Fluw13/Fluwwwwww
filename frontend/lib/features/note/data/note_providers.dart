import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/data/note_repository.dart';
import 'package:fluw/features/note/domain/note_entry.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) => NoteRepository(ref.watch(appDatabaseProvider)));

/// Entries that can fall on the week starting [monday]: night entries of Monday start at 00:01 and the 00:00 of the
/// next Monday still belongs to Sunday, so the window is one day wider on each side and callers group by placement.
final weekNoteEntriesProvider = StreamProvider.family<List<NoteEntry>, CalendarDate>((ref, monday) {
  final start = monday.addDays(-1);
  final end = monday.addDays(8);
  return ref
      .watch(noteRepositoryProvider)
      .watchBetween(DateTime(start.year, start.month, start.day), DateTime(end.year, end.month, end.day));
});
