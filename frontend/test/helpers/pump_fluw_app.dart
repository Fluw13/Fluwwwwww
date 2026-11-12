import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/fluw_app.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts the real app with in-memory settings and returns them so tests can check what was saved.
Future<SharedPreferences> pumpFluwApp(WidgetTester tester, {Map<String, Object> storedSettings = const {}}) async {
  SharedPreferences.setMockInitialValues(storedSettings);
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [themeModeStorageProvider.overrideWithValue(ThemeModeStorage(preferences))],
      child: const FluwApp(),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}
