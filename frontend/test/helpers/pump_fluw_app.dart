import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_overrides.dart';
import 'package:fluw/app/fluw_app.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_client_provider.dart';
import 'package:fluw/core/network/backend_warm_up.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/clock_provider.dart';
import 'package:fluw/core/time/current_hour_provider.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/reminders/data/notification_scheduler.dart';
import 'package:fluw/features/reminders/data/reminder_settings_storage.dart';
import 'package:fluw/features/scan/presentation/barcode_camera.dart';
import 'package:fluw/features/search/data/recent_searches_storage.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_barcode_camera.dart';
import 'fake_notification_scheduler.dart';
import 'in_memory_database.dart';

/// The date every app test runs on, so ages and targets never change with the real calendar.
final CalendarDate appTestToday = CalendarDate(2026, 11, 11);

/// The hour every app test runs at: morning, so no evening-only text shows unless a test asks for it.
const int appTestHour = 9;

/// Starts the real app with in-memory settings and database, and returns the settings so tests can check what was
/// saved. The database closes with the app, also when a test fails; reach it through [appContainer].
/// Pass [httpClient] (a `MockClient`) to answer backend calls; without one any call fails the test as a network error.
/// [overrides] apply in a child scope, so they replace the defaults above.
Future<SharedPreferences> pumpFluwApp(
  WidgetTester tester, {
  Map<String, Object> storedSettings = const {},
  http.Client? httpClient,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(storedSettings);
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeStorageProvider.overrideWithValue(ThemeModeStorage(preferences)),
        recentSearchesStorageProvider.overrideWithValue(RecentSearchesStorage(preferences)),
        reminderSettingsStorageProvider.overrideWithValue(ReminderSettingsStorage(preferences)),
        notificationSchedulerProvider.overrideWithValue(FakeNotificationScheduler()),
        barcodeCameraProvider.overrideWithValue(FakeBarcodeCamera()),
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
        currentHourProvider.overrideWithValue(appTestHour),
        clockProvider.overrideWithValue(
          () => DateTime(appTestToday.year, appTestToday.month, appTestToday.day, appTestHour),
        ),
        // No warm-up calls in tests unless a test asks for them, so mock backends see only the requests they expect.
        backendWarmUpProvider.overrideWithValue(() async {}),
        appDatabaseProvider.overrideWith((ref) {
          final database = openInMemoryDatabase();
          ref.onDispose(database.close);
          return database;
        }),
      ],
      // A nested scope, because Riverpod rejects overriding the same provider twice in one container.
      child: overrides.isEmpty ? const FluwApp() : ProviderScope(overrides: overrides, child: const FluwApp()),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

/// The fake camera of the app started by [pumpFluwApp].
FakeBarcodeCamera appBarcodeCamera(WidgetTester tester) =>
    appContainer(tester).read(barcodeCameraProvider) as FakeBarcodeCamera;

/// The fake notification system of the app started by [pumpFluwApp].
FakeNotificationScheduler appNotifications(WidgetTester tester) =>
    appContainer(tester).read(notificationSchedulerProvider) as FakeNotificationScheduler;

/// The providers of the app started by [pumpFluwApp].
ProviderContainer appContainer(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(FluwApp)));
