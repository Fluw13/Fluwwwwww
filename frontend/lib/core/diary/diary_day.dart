import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/diary_reader.dart';
import 'package:fluw/core/diary/note_day.dart';
import 'package:fluw/core/time/calendar_date.dart';

/// One diary day as other features see it. [day] is null when nothing was logged.
final class DiaryDay {
  const DiaryDay({required this.date, required this.day, required this.unreadableCount});

  final CalendarDate date;
  final NoteDay? day;
  final int unreadableCount;

  int get entryCount => day?.entriesBySlot.values.fold<int>(0, (sum, entries) => sum + entries.length) ?? 0;
}

/// Night entries of [date] start at 00:01 and the 00:00 of the next day still belongs to its Tối, so the window runs
/// from 00:00 to 00:01 of the next day and entries are grouped by placement.
final diaryDayProvider = StreamProvider.autoDispose.family<DiaryDay, CalendarDate>((ref, date) {
  final next = date.addDays(1);
  return ref
      .watch(diaryReaderProvider)
      .watchBetween(DateTime(date.year, date.month, date.day), DateTime(next.year, next.month, next.day, 0, 1))
      .map(
        (window) => DiaryDay(
          date: date,
          day: groupNoteEntries(window.entries).where((candidate) => candidate.date == date).firstOrNull,
          unreadableCount: window.unreadableCount,
        ),
      );
});
