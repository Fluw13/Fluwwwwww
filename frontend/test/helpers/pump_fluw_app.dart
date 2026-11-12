import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/fluw_app.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'in_memory_database.dart';

/// The date every app test runs on, so ages and targets never change with the real calendar.
final CalendarDate appTestToday = CalendarDate(2026, 11, 11);

/// Starts the real app with in-memory settings and database, and returns the settings so tests can check what was
/// saved. The database closes with the app, also when a test fails; reach it through [appContainer].
Future<SharedPreferences> pumpFluwApp(WidgetTester tester, {Map<String, Object> storedSettings = const {}}) async {
  SharedPreferences.setMockInitialValues(storedSettings);
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeStorageProvider.overrideWithValue(ThemeModeStorage(preferences)),
        todayProvider.overrideWithValue(appTestToday),
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

/// The providers of the app started by [pumpFluwApp].
ProviderContainer appContainer(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(FluwApp)));
