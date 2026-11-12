import 'package:drift/drift.dart';
import 'package:fluw/core/database/app_database.steps.dart';
import 'package:fluw/core/database/profile_tables.dart';

part 'app_database.g.dart';

/// Raising [schemaVersion]: change the tables, then run `dart run drift_dev make-migrations` (see CLAUDE.md section 4)
/// and add the new step below.
@DriftDatabase(tables: [Profiles, ProfileConditions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (migrator, schema) async {
        await migrator.addColumn(schema.profiles, schema.profiles.displayName);
        await migrator.addColumn(schema.profiles, schema.profiles.bmrFormula);
      },
    ),
  );
}
