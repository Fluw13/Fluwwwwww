import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fluw/core/database/app_database.dart';

/// Each test gets its own empty SQLite database that lives only in memory.
AppDatabase openInMemoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
