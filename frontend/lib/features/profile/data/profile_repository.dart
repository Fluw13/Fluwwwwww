import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/features/profile/data/profile_mapper.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';

final class ProfileRepository {
  ProfileRepository(this._database);

  final AppDatabase _database;

  Future<StoredProfile> load() async => _toStoredProfile(await _profileQuery().get());

  /// Emits again whenever the profile or its conditions change.
  Stream<StoredProfile> watch() => _profileQuery().watch().map(_toStoredProfile);

  /// SQLite turns NaN into NULL, so a non-finite number would either break a NOT NULL column or silently come back
  /// as "not set"; it is rejected here instead.
  Future<void> save(HealthProfile profile) async {
    final numbers = [profile.heightCm, profile.weightKg, profile.targetWeightKg, ?profile.weeklyChangeKg];
    if (numbers.any((number) => !number.isFinite)) {
      throw ArgumentError.value(profile, 'profile', 'Hồ sơ có số không hữu hạn');
    }
    await _database.transaction(() async {
      await _database.into(_database.profiles).insertOnConflictUpdate(profileToRow(profile));
      await _database.delete(_database.profileConditions).go();
      await _database.batch((batch) {
        batch.insertAll(_database.profileConditions, [
          for (final key in conditionsToKeys(profile.conditions)) ProfileConditionsCompanion.insert(conditionKey: key),
        ]);
      });
    });
  }

  Future<void> clear() {
    return _database.transaction(() async {
      await _database.delete(_database.profileConditions).go();
      await _database.delete(_database.profiles).go();
    });
  }

  /// One query over both tables, so a reader never sees a profile with half-saved conditions and the stream reacts
  /// to changes in either table.
  JoinedSelectStatement<HasResultSet, dynamic> _profileQuery() {
    return _database.select(_database.profiles).join([
      leftOuterJoin(_database.profileConditions, const Constant(true)),
    ]);
  }

  StoredProfile _toStoredProfile(List<TypedResult> rows) {
    if (rows.isEmpty) {
      return const NoProfile();
    }
    final profile = profileFromRow(rows.first.readTable(_database.profiles), [
      for (final row in rows)
        if (row.readTableOrNull(_database.profileConditions) case final condition?) condition.conditionKey,
    ]);
    return profile == null ? const UnreadableProfile() : LoadedProfile(profile);
  }
}
