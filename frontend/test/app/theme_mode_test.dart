import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/home/presentation/home_screen.dart';

import '../helpers/pump_fluw_app.dart';

Brightness _currentBrightness(WidgetTester tester) => Theme.of(tester.element(find.byType(HomeScreen))).brightness;

void main() {
  testWidgets('chưa chọn thì theo chế độ Sáng/Tối của máy', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpFluwApp(tester);

    expect(_currentBrightness(tester), Brightness.dark);
  });

  testWidgets('chạm nút mặt trăng thì chuyển sang tối và lưu lại lựa chọn', (tester) async {
    final settings = await pumpFluwApp(tester);

    await tester.tap(find.byTooltip('Chuyển sang giao diện tối'));
    await tester.pumpAndSettle();

    expect(_currentBrightness(tester), Brightness.dark);
    expect(settings.getString('theme_mode'), 'dark');

    await tester.tap(find.byTooltip('Chuyển sang giao diện sáng'));
    await tester.pumpAndSettle();

    expect(_currentBrightness(tester), Brightness.light);
    expect(settings.getString('theme_mode'), 'light');
  });

  testWidgets('mở lại app thì dùng lựa chọn đã lưu, kể cả khi máy đang để sáng', (tester) async {
    await pumpFluwApp(tester, storedSettings: {'theme_mode': 'dark'});

    expect(_currentBrightness(tester), Brightness.dark);
  });

  testWidgets('giá trị đã lưu bị hỏng thì quay về theo máy', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpFluwApp(tester, storedSettings: {'theme_mode': 'tím'});

    expect(_currentBrightness(tester), Brightness.dark);
  });
}
