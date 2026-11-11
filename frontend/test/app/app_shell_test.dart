import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/fluw_app.dart';
import 'package:fluw/features/home/presentation/home_screen.dart';
import 'package:fluw/features/note/presentation/note_screen.dart';
import 'package:fluw/features/profile/presentation/profile_screen.dart';
import 'package:fluw/features/scan/presentation/scan_screen.dart';
import 'package:fluw/features/search/presentation/search_screen.dart';

Type _expectedScreen(AppTab tab) {
  return switch (tab) {
    AppTab.home => HomeScreen,
    AppTab.search => SearchScreen,
    AppTab.scan => ScanScreen,
    AppTab.note => NoteScreen,
    AppTab.profile => ProfileScreen,
  };
}

Future<void> _openTab(WidgetTester tester, AppTab tab) async {
  await tester.tap(find.widgetWithText(NavigationDestination, tab.label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mở app thì vào Trang chủ và thanh điều hướng có đủ các tab', (tester) async {
    await tester.pumpWidget(const FluwApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    for (final tab in AppTab.values) {
      expect(find.widgetWithText(NavigationDestination, tab.label), findsOneWidget);
    }
  });

  testWidgets('chạm vào từng tab thì mở đúng màn hình và chỉ màn đó hiển thị', (tester) async {
    await tester.pumpWidget(const FluwApp());
    await tester.pumpAndSettle();

    for (final tab in [...AppTab.values.reversed, AppTab.home]) {
      await _openTab(tester, tab);

      for (final other in AppTab.values) {
        expect(find.byType(_expectedScreen(other)), other == tab ? findsOneWidget : findsNothing);
      }
    }
  });

  testWidgets('màn 320x568 với cỡ chữ 200% không tràn bố cục ở mọi tab', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const FluwApp());
    await tester.pumpAndSettle();

    for (final tab in AppTab.values) {
      await _openTab(tester, tab);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('giao diện theo chế độ Sáng/Tối của máy', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const FluwApp());
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.byType(HomeScreen))).brightness, Brightness.dark);
  });
}
