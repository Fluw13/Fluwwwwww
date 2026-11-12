import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fluw/core/database/app_database.dart';

/// Each test gets its own empty SQLite database that lives only in memory. Streams close synchronously so widget
/// tests do not end with drift's close timer still pending.
AppDatabase openInMemoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
}
