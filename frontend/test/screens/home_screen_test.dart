import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/scanner_screen.dart';
import 'package:frontend/data/api/fluw_api_scope.dart';

import '../helpers/fake_backend.dart';
import '../helpers/fake_mobile_scanner_platform.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    FluwApiScope(
      client: FakeBackend().client,
      child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _waitForTransition(WidgetTester tester) async {
  await tester.pump();
  // The scan line repeats forever, so wait for the route transition only.
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('bấm nút quét hai lần liên tiếp chỉ mở một màn quét', (
    tester,
  ) async {
    FakeMobileScannerPlatform.install();
    await _pumpHome(tester);

    // Two taps landing in the same frame, before the navigator starts
    // absorbing pointers for the transition.
    final VoidCallback openScanner = tester
        .widget<ElevatedButton>(find.byType(ElevatedButton))
        .onPressed!;
    openScanner();
    openScanner();
    await _waitForTransition(tester);

    expect(find.byType(ScannerScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
    'chọn "Nhập mã thủ công" thì quay về Home và con trỏ vào ô tìm kiếm',
    (tester) async {
      FakeMobileScannerPlatform.install();
      await _pumpHome(tester);

      await tester.tap(find.text('QUÉT MÃ VẠCH'));
      await _waitForTransition(tester);
      await tester.tap(find.text('Nhập mã thủ công'));
      await tester.pumpAndSettle();

      expect(find.byType(ScannerScreen), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
    },
  );

  testWidgets('đóng màn quét rồi mở lại được', (tester) async {
    FakeMobileScannerPlatform.install();
    await _pumpHome(tester);

    await tester.tap(find.text('QUÉT MÃ VẠCH'));
    await _waitForTransition(tester);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(ScannerScreen), findsNothing);

    await tester.tap(find.text('QUÉT MÃ VẠCH'));
    await _waitForTransition(tester);
    expect(find.byType(ScannerScreen), findsOneWidget);
  });
}
