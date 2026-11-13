import 'package:drift/drift.dart';

/// Holds at most one row: the app keeps a single health profile on the device.
@DataClassName('ProfileRow')
class Profiles extends Table {
  IntColumn get id => integer()();
  TextColumn get displayName => text().nullable()();
  TextColumn get sex => text()();

  /// Added in schema v2; only set when the sex is "other".
  TextColumn get bmrFormula => text().nullable()();

  /// `yyyy-MM-dd`, so the birthday never shifts with the time zone.
  TextColumn get birthDate => text()();
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  RealColumn get targetWeightKg => real()();
  TextColumn get activityLevel => text()();
  TextColumn get trainingType => text()();
  RealColumn get weeklyChangeKg => real().nullable()();
  TextColumn get conditionNote => text().nullable()();
  BoolColumn get limitsSugar => boolean()();

  /// Added in schema v3. Old rows read as the regular style.
  TextColumn get dietStyle => text().nullable()();
  TextColumn get allergyNote => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = $singleProfileId)'];
}

const int singleProfileId = 1;

@DataClassName('ProfileConditionRow')
class ProfileConditions extends Table {
  TextColumn get conditionKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {conditionKey};
}

/// Added in schema v3.
@DataClassName('ProfileAllergyRow')
class ProfileAllergies extends Table {
  TextColumn get allergenKey => text()();
  TextColumn get severityKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {allergenKey};
}

/// Added in schema v3.
@DataClassName('ProfilePreferenceRow')
class ProfilePreferences extends Table {
  TextColumn get preferenceKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {preferenceKey};
}

/// Added in schema v3. One weigh-in per calendar day (`yyyy-MM-dd`).
@DataClassName('WeightEntryRow')
class WeightEntries extends Table {
  TextColumn get date => text()();
  RealColumn get weightKg => real()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}
