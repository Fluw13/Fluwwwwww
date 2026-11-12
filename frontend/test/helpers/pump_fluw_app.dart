import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/fluw_app.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'in_memory_database.dart';

/// Starts the real app with in-memory settings and database, and returns them so tests can check what was saved.
Future<SharedPreferences> pumpFluwApp(WidgetTester tester, {Map<String, Object> storedSettings = const {}}) async {
  SharedPreferences.setMockInitialValues(storedSettings);
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeStorageProvider.overrideWithValue(ThemeModeStorage(preferences)),
        appDatabaseProvider.overrideWith((ref) {
          final database = openInMemoryDatabase();
          ref.onDispose(database.close);
          return database;
        }),
      ],
      child: const FluwApp(),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}
