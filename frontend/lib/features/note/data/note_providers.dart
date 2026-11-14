import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/data/note_repository.dart';
import 'package:fluw/features/note/data/note_window.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) => NoteRepository(ref.watch(appDatabaseProvider)));

/// Entries of the week starting [monday]. The 00:00 of the next Monday still belongs to Sunday's Tối (seconds are
/// dropped, so up to 00:00:59), so the window ends at 00:01 of the next Monday; callers group by placement.
final weekNoteEntriesProvider = StreamProvider.autoDispose.family<NoteWindow, CalendarDate>((ref, monday) {
  final next = monday.addDays(DateTime.daysPerWeek);
  return ref
      .watch(noteRepositoryProvider)
      .watchBetween(DateTime(monday.year, monday.month, monday.day), DateTime(next.year, next.month, next.day, 0, 1));
});
