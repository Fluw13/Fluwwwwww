import 'package:drift/drift.dart';
import 'package:fluw/core/database/profile_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Profiles, ProfileConditions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
