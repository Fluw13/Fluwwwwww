import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/shell/fluw_bottom_bar.dart';
import 'package:fluw/features/home/presentation/home_screen.dart';
import 'package:fluw/features/note/presentation/note_screen.dart';
import 'package:fluw/features/profile/presentation/profile_screen.dart';
import 'package:fluw/features/scan/presentation/scan_screen.dart';
import 'package:fluw/features/search/presentation/search_screen.dart';

import '../helpers/load_app_fonts.dart';
import '../helpers/pump_fluw_app.dart';

Type _expectedScreen(AppTab tab) {
  return switch (tab) {
    AppTab.home => HomeScreen,
    AppTab.search => SearchScreen,
    AppTab.scan => ScanScreen,
    AppTab.note => NoteScreen,
    AppTab.profile => ProfileScreen,
  };
}

Finder _tabItem(AppTab tab) =>
    find.descendant(of: find.byType(FluwBottomBar), matching: find.bySemanticsLabel(tab.label));

Future<void> _openTab(WidgetTester tester, AppTab tab) async {
  await tester.tap(_tabItem(tab));
  await tester.pumpAndSettle();
}

void _expectOnly(AppTab tab) {
  for (final other in AppTab.values) {
    expect(find.byType(_expectedScreen(other)), other == tab ? findsOneWidget : findsNothing);
  }
  expect(find.widgetWithText(AppBar, tab.title), findsOneWidget);
}

void main() {
  testWidgets('thanh dưới có đủ 5 tab theo thiết kế, mở app vào Trang Chủ', (tester) async {
    await pumpFluwApp(tester);

    expect(AppTab.values.map((tab) => tab.label), ['Trang Chủ', 'Tra Cứu', 'Quét Món', 'Nhật Ký', 'Hồ Sơ']);
    for (final tab in AppTab.values) {
      expect(_tabItem(tab), findsOneWidget);
    }
    _expectOnly(AppTab.home);
  });

  testWidgets('chạm từng tab thì mở đúng màn và header đổi tiêu đề theo màn', (tester) async {
    await pumpFluwApp(tester);

    for (final tab in [...AppTab.values.reversed, AppTab.home]) {
      await _openTab(tester, tab);
      _expectOnly(tab);
    }
  });

  testWidgets('nút Quét tròn ở giữa mở màn Quét', (tester) async {
    await pumpFluwApp(tester);

    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle();

    _expectOnly(AppTab.scan);
  });

  testWidgets('chạm avatar trên header thì mở Hồ Sơ', (tester) async {
    await pumpFluwApp(tester);

    await tester.tap(find.byTooltip('Hồ sơ'));
    await tester.pumpAndSettle();

    _expectOnly(AppTab.profile);
  });

  // 200% is Android's largest font size; 310% is iOS's largest accessibility size.
  for (final textScale in [2.0, 3.1]) {
    testWidgets('màn 320x568 với cỡ chữ ${(textScale * 100).round()}% không tràn bố cục ở mọi tab', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await loadAppFonts();

      await pumpFluwApp(tester);

      for (final tab in AppTab.values) {
        await _openTab(tester, tab);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
