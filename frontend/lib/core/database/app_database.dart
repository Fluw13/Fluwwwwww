import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.steps.dart';
import 'package:fluw/core/database/profile_tables.dart';

part 'app_database.g.dart';

/// Raising [schemaVersion]: change the tables, then run `dart run drift_dev make-migrations` (see CLAUDE.md section 4)
/// and add the new step below.
@DriftDatabase(tables: [Profiles, ProfileConditions, ProfileAllergies, ProfilePreferences, WeightEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (migrator, schema) async {
        await migrator.addColumn(schema.profiles, schema.profiles.displayName);
        await migrator.addColumn(schema.profiles, schema.profiles.bmrFormula);
      },
      from2To3: (migrator, schema) async {
        await migrator.addColumn(schema.profiles, schema.profiles.dietStyle);
        await migrator.addColumn(schema.profiles, schema.profiles.allergyNote);
        await migrator.createTable(schema.profileAllergies);
        await migrator.createTable(schema.profilePreferences);
        await migrator.createTable(schema.weightEntries);
      },
    ),
  );
}
