import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_overrides.dart';
import 'package:fluw/app/fluw_app.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_client_provider.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/search/data/recent_searches_storage.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'in_memory_database.dart';

/// The date every app test runs on, so ages and targets never change with the real calendar.
final CalendarDate appTestToday = CalendarDate(2026, 11, 11);

/// Starts the real app with in-memory settings and database, and returns the settings so tests can check what was
/// saved. The database closes with the app, also when a test fails; reach it through [appContainer].
/// Pass [httpClient] (a `MockClient`) to answer backend calls; without one any call fails the test as a network error.
Future<SharedPreferences> pumpFluwApp(
  WidgetTester tester, {
  Map<String, Object> storedSettings = const {},
  http.Client? httpClient,
}) async {
  SharedPreferences.setMockInitialValues(storedSettings);
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeStorageProvider.overrideWithValue(ThemeModeStorage(preferences)),
        recentSearchesStorageProvider.overrideWithValue(RecentSearchesStorage(preferences)),
        apiClientProvider.overrideWithValue(
          ApiClient(
            httpClient:
                httpClient ?? MockClient((request) async => throw http.ClientException('không có mạng trong test')),
            baseUri: Uri.parse('https://api.test'),
            timeout: const Duration(seconds: 70),
          ),
        ),
        ...crossFeatureOverrides(),
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
