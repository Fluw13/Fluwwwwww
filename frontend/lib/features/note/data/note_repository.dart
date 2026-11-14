import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/features/note/data/note_entry_mapper.dart';
import 'package:fluw/features/note/data/note_window.dart';
import 'package:fluw/features/note/domain/note_entry.dart';

final class NoteRepository {
  NoteRepository(this._database);

  final AppDatabase _database;

  /// Entries eaten from [from] (inclusive) to [to] (exclusive), oldest first. Unreadable rows are left out and counted.
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

  /// No finite-number check here: `NoteEntry` and `Nutrients` already reject NaN and infinity, which SQLite would
  /// store as NULL.
  Future<void> add(NoteEntry entry) => _database.into(_database.noteEntries).insert(noteEntryToRow(entry));

  Future<void> delete(String id) =>
      (_database.delete(_database.noteEntries)..where((table) => table.id.equals(id))).go();
}
