import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';

const Size phoneSize = Size(390, 844);

/// Renders [child] on a phone-sized screen with the real app theme.
Future<void> pumpOnPhone(
  WidgetTester tester,
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
  Size size = phoneSize,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: Scaffold(body: child),
    ),
  );
}
