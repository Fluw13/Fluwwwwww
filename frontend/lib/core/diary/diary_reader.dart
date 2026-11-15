import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/note_window.dart';

/// Read access to the diary for features other than the diary itself (home, reminders, reports); `app/` provides
/// the real one, so they never import the diary feature.
abstract interface class DiaryReader {
  /// Entries eaten from [from] (inclusive) to [to] (exclusive), oldest first, with the count of unreadable rows.
  Stream<NoteWindow> watchBetween(DateTime from, DateTime to);
}

final diaryReaderProvider = Provider<DiaryReader>(
  (ref) => throw UnimplementedError('diaryReaderProvider phải được nối trong app/app_overrides.dart'),
);
