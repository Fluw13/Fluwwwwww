import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/features/profile/data/dietary_mapper.dart';
import 'package:fluw/features/profile/data/profile_mapper.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';

final class ProfileRepository {
  ProfileRepository(this._database);

  final AppDatabase _database;

  /// Reads every profile table in one transaction, so a reader never sees a half-saved profile.
  Future<StoredProfile> load() => _database.transaction(() async {
    final row = await _database.select(_database.profiles).getSingleOrNull();
    if (row == null) {
      return const NoProfile();
    }
    final conditionRows = await _database.select(_database.profileConditions).get();
    final allergyRows = await _database.select(_database.profileAllergies).get();
    final preferenceRows = await _database.select(_database.profilePreferences).get();
    final dietary = dietaryFromRows(
      dietStyleKey: row.dietStyle,
      allergyNote: row.allergyNote,
      allergyRows: allergyRows,
      preferenceKeys: [for (final preference in preferenceRows) preference.preferenceKey],
    );
    final profile = profileFromRow(row, [for (final condition in conditionRows) condition.conditionKey], dietary);
    return profile == null ? const UnreadableProfile() : LoadedProfile(profile);
  });

  /// Emits now and again after any change to the profile tables.
  Stream<StoredProfile> watch() => _database
      .customSelect(
        'SELECT 1',
        readsFrom: {
          _database.profiles,
          _database.profileConditions,
          _database.profileAllergies,
          _database.profilePreferences,
        },
      )
      .watch()
      .asyncMap((_) => load());

  /// SQLite turns NaN into NULL, so a non-finite number would either break a NOT NULL column or silently come back
  /// as "not set"; it is rejected here instead.
  Future<void> save(HealthProfile profile) async {
    final numbers = [profile.heightCm, profile.weightKg, profile.targetWeightKg, ?profile.weeklyChangeKg];
    if (numbers.any((number) => !number.isFinite)) {
      throw ArgumentError.value(profile, 'profile', 'Hồ sơ có số không hữu hạn');
    }
    await _database.transaction(() async {
      await _database.into(_database.profiles).insertOnConflictUpdate(profileToRow(profile));
      await _deleteChildRows();
      await _database.batch((batch) {
        batch
          ..insertAll(_database.profileConditions, [
            for (final key in conditionsToKeys(profile.conditions))
              ProfileConditionsCompanion.insert(conditionKey: key),
          ])
          ..insertAll(_database.profileAllergies, allergiesToRows(profile.dietary))
          ..insertAll(_database.profilePreferences, preferencesToRows(profile.dietary));
      });
    });
  }

  /// Also drops the weight history: a new profile must not measure progress from someone else's weigh-ins.
  Future<void> clear() {
    return _database.transaction(() async {
      await _deleteChildRows();
      await _database.delete(_database.weightEntries).go();
      await _database.delete(_database.profiles).go();
    });
  }

  Future<void> _deleteChildRows() async {
    await _database.delete(_database.profileConditions).go();
    await _database.delete(_database.profileAllergies).go();
    await _database.delete(_database.profilePreferences).go();
  }
}
