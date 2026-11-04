import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/api/fluw_api_client.dart';
import 'package:frontend/data/api/fluw_api_scope.dart';

const Size phoneSize = Size(390, 844);

/// Renders [child] on a phone-sized screen with the real app theme.
Future<void> pumpOnPhone(
  WidgetTester tester,
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
  Size size = phoneSize,
  FluwApiClient? client,
}) {
  return pumpScreen(
    tester,
    Scaffold(body: child),
    themeMode: themeMode,
    size: size,
    client: client,
  );
}

/// Renders a whole [screen] (with its own Scaffold) like the app does.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  ThemeMode themeMode = ThemeMode.light,
  Size size = phoneSize,
  FluwApiClient? client,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final Widget app = MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    home: screen,
  );
  await tester.pumpWidget(
    client == null ? app : FluwApiScope(client: client, child: app),
  );
}

/// Lets a pending request settle and the 220 ms cross-fade finish.
Future<void> settleRequest(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
