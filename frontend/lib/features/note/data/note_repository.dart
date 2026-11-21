import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/diary/diary_reader.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/diary/note_window.dart';
import 'package:fluw/core/diary/recent_foods.dart';
import 'package:fluw/core/diary/recent_foods_reader.dart';
import 'package:fluw/features/note/data/note_entry_mapper.dart';

final class NoteRepository implements DiaryReader, RecentFoodsReader {
  NoteRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<NoteWindow> watchBetween(DateTime from, DateTime to) {
    final query = _database.select(_database.noteEntries)
      ..where(
        (table) =>
            table.eatenAtUtcMs.isBiggerOrEqualValue(from.toUtc().millisecondsSinceEpoch) &
            table.eatenAtUtcMs.isSmallerThanValue(to.toUtc().millisecondsSinceEpoch),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.eatenAtUtcMs), (table) => OrderingTerm.asc(table.id)]);
    return query.watch().map((rows) {
      final entries = List<NoteEntry>.unmodifiable([for (final row in rows) ?noteEntryFromRow(row)]);
      return NoteWindow(entries: entries, unreadableCount: rows.length - entries.length);
    });
  }

  /// Reads only the newest [_recentRowsRead] entries: plenty of different foods, and bounded so a diary kept for years
  /// stays fast.
  @override
  Stream<List<NoteEntry>> watchRecentFoods({required int limit}) {
    final query = _database.select(_database.noteEntries)
      ..orderBy([(table) => OrderingTerm.desc(table.eatenAtUtcMs), (table) => OrderingTerm.desc(table.id)])
      ..limit(_recentRowsRead);
    return query.watch().map(
      (rows) => distinctRecentFoods([for (final row in rows) ?noteEntryFromRow(row)], limit: limit),
    );
  }

  static const int _recentRowsRead = 200;

  /// No finite-number check here: `NoteEntry` and `Nutrients` already reject NaN and infinity, which SQLite would
  /// store as NULL.
  Future<void> add(NoteEntry entry) => _database.into(_database.noteEntries).insert(noteEntryToRow(entry));

  /// Replaces the stored entry with the same id (a changed amount, day or slot). Throws [StateError] when it is gone,
  /// e.g. deleted from another screen, so the caller can say so instead of claiming it was saved.
  Future<void> update(NoteEntry entry) async {
    final replaced = await _database.update(_database.noteEntries).replace(noteEntryToRow(entry));
    if (!replaced) {
      throw StateError('Món ${entry.id} không còn trong Nhật ký');
    }
  }

  Future<void> delete(String id) =>
      (_database.delete(_database.noteEntries)..where((table) => table.id.equals(id))).go();
}
