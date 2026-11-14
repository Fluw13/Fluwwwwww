import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/features/note/data/note_entry_mapper.dart';
import 'package:fluw/features/note/domain/note_entry.dart';

final class NoteRepository {
  NoteRepository(this._database);

  final AppDatabase _database;

  /// Entries eaten from [from] (inclusive) to [to] (exclusive), oldest first. Unreadable rows are left out.
  Stream<List<NoteEntry>> watchBetween(DateTime from, DateTime to) {
    final query = _database.select(_database.noteEntries)
      ..where(
        (table) =>
            table.eatenAtUtcMs.isBiggerOrEqualValue(from.toUtc().millisecondsSinceEpoch) &
            table.eatenAtUtcMs.isSmallerThanValue(to.toUtc().millisecondsSinceEpoch),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.eatenAtUtcMs), (table) => OrderingTerm.asc(table.id)]);
    return query.watch().map((rows) => List.unmodifiable([for (final row in rows) ?noteEntryFromRow(row)]));
  }

  /// SQLite turns NaN into NULL, which would read back as "no data"; such numbers are rejected here.
  Future<void> add(NoteEntry entry) async {
    final numbers = [entry.quantity, ...entry.facts.per100.asMap().values];
    if (numbers.any((number) => !number.isFinite)) {
      throw ArgumentError.value(entry, 'entry', 'Món có số không hữu hạn');
    }
    await _database.into(_database.noteEntries).insert(noteEntryToRow(entry));
  }

  Future<void> delete(String id) =>
      (_database.delete(_database.noteEntries)..where((table) => table.id.equals(id))).go();
}
