import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/history/session_history.dart';
import 'package:frontend/core/settings/theme_mode_controller.dart';
import 'package:frontend/core/settings/theme_mode_store.dart';
import 'package:frontend/main.dart';

class MemoryThemeModeStore implements ThemeModeStore {
  ThemeMode? value;

  @override
  Future<ThemeMode?> read() async => value;

  @override
  Future<void> write(ThemeMode mode) async => value = mode;
}

/// Pumps the real app shell (theme, theme mode and history scopes) around [home].
Future<ThemeModeController> pumpFluwApp(
  WidgetTester tester,
  Widget home, {
  SessionHistory? history,
  ThemeMode themeMode = ThemeMode.light,
  MemoryThemeModeStore? store,
}) async {
  final ThemeModeController controller = ThemeModeController(store ?? MemoryThemeModeStore());
  await controller.setMode(themeMode);
  await tester.pumpWidget(
    FluwApp(themeModeController: controller, sessionHistory: history ?? SessionHistory(), home: home),
  );
  await tester.pump();
  return controller;
}
