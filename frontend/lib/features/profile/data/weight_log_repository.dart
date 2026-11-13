import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/weight_entry.dart';

final class WeightLogRepository {
  WeightLogRepository(this._database);

  final AppDatabase _database;

  /// Oldest first. Rows with an unreadable date are skipped: a lost weigh-in only shortens the history.
  Stream<List<WeightEntry>> watch() {
    final query = _database.select(_database.weightEntries)..orderBy([(table) => OrderingTerm.asc(table.date)]);
    return query.watch().map(
      (rows) => List.unmodifiable([
        for (final row in rows)
          if (CalendarDate.tryParse(row.date) case final date?) WeightEntry(date: date, weightKg: row.weightKg),
      ]),
    );
  }

  /// Saves the weigh-in and makes it the profile's current weight in one transaction, so targets follow at once.
  /// Only a weigh-in on or after the newest one updates the profile; back-filling an older day keeps it.
  Future<void> record(WeightEntry entry) async {
    if (!entry.weightKg.isFinite) {
      throw ArgumentError.value(entry.weightKg, 'weightKg', 'Cân nặng phải là số hữu hạn');
    }
    await _database.transaction(() async {
      final newest =
          await (_database.select(_database.weightEntries)
                ..orderBy([(table) => OrderingTerm.desc(table.date)])
                ..limit(1))
              .getSingleOrNull();
      await _database
          .into(_database.weightEntries)
          .insertOnConflictUpdate(WeightEntriesCompanion.insert(date: entry.date.toString(), weightKg: entry.weightKg));
      if (newest == null || newest.date.compareTo(entry.date.toString()) <= 0) {
        await _database.update(_database.profiles).write(ProfilesCompanion(weightKg: Value(entry.weightKg)));
      }
    });
  }
}
