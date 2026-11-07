import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/history/session_history.dart';
import 'package:frontend/models/product_summary.dart';
import 'package:frontend/screens/account_screen.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/product_detail_screen.dart';
import 'package:frontend/screens/scanner_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/home/zero_intro_card.dart';
import 'package:frontend/widgets/product/product_card.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_mobile_scanner_platform.dart';
import '../helpers/fluw_app_harness.dart';

ApiService _api() {
  return ApiService(
    client: MockClient(
      (_) async => http.Response(
        '{"success":false,"error":"Không tìm thấy"}',
        404,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
}

ProductSummary _scan(String barcode, String name) {
  return ProductSummary(barcode: barcode, name: name, brand: 'Hãng', imageUrl: '', score: 5.6, calories: 120);
}

Future<void> _pumpHome(WidgetTester tester, {SessionHistory? history, ThemeMode themeMode = ThemeMode.light}) {
  return pumpFluwApp(tester, HomeScreen(apiService: _api()), history: history, themeMode: themeMode);
}

Future<void> _waitForScannerTransition(WidgetTester tester) async {
  await tester.pump();
  // The scan line repeats forever, so wait for the route transition only.
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('lần đầu mở: lời chào, ô tìm kiếm, giới thiệu Zero, nút quét, nút tài khoản (${mode.name})',
        (tester) async {
      await _pumpHome(tester, themeMode: mode);

      expect(find.text('Bạn đang ăn món gì?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ZeroIntroCard), findsOneWidget);
      expect(find.text('Quét mã vạch'), findsOneWidget);
      expect(find.byTooltip('Tài khoản'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tìm kiếm: lưu từ khóa vào lịch sử trong phiên rồi mở trang chi tiết', (tester) async {
    final SessionHistory history = SessionHistory();
    await _pumpHome(tester, history: history);

    await tester.enterText(find.byType(TextField), '  sữa chua  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(history.searches, ['sữa chua']);
    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });

  testWidgets('ô tìm kiếm trống thì không làm gì', (tester) async {
    final SessionHistory history = SessionHistory();
    await _pumpHome(tester, history: history);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Tìm'));
    await tester.pumpAndSettle();

    expect(history.searches, isEmpty);
    expect(find.byType(ProductDetailScreen), findsNothing);
  });

  testWidgets('có lịch sử thì hiện từ khóa gần đây và sản phẩm vừa quét thay cho giới thiệu', (tester) async {
    final SessionHistory history = SessionHistory()
      ..addSearch('mì hảo hảo')
      ..addScan(_scan('1', 'Sản phẩm 1'))
      ..addScan(_scan('2', 'Sản phẩm 2'))
      ..addScan(_scan('3', 'Sản phẩm 3'))
      ..addScan(_scan('4', 'Sản phẩm 4'));
    await _pumpHome(tester, history: history);

    expect(find.widgetWithText(ActionChip, 'mì hảo hảo'), findsOneWidget);
    expect(find.byType(ZeroIntroCard), findsNothing);
    expect(find.text('Vừa quét'), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(3));
    expect(find.text('Sản phẩm 4'), findsOneWidget, reason: 'mới nhất lên đầu');
    expect(find.text('Sản phẩm 1'), findsNothing);
  });

  testWidgets('lịch sử thay đổi thì Home cập nhật ngay', (tester) async {
    final SessionHistory history = SessionHistory();
    await _pumpHome(tester, history: history);
    expect(find.byType(ProductCard), findsNothing);

    history.addScan(_scan('8934563138165', 'Mì Hảo Hảo'));
    await tester.pump();

    expect(find.text('Mì Hảo Hảo'), findsOneWidget);
  });

  testWidgets('nút tài khoản mở màn Tài khoản', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byTooltip('Tài khoản'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
  });

  testWidgets('màn 320 px với chữ 200% không tràn, kể cả khi có lịch sử', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final SessionHistory history = SessionHistory()
      ..addSearch('một từ khóa tìm kiếm khá dài để thử')
      ..addScan(_scan('1', 'Bánh quy yến mạch nguyên hạt vị mật ong hộp lớn'));
    await _pumpHome(tester, history: history);

    expect(tester.takeException(), isNull);
  });

  group('lịch sử theo cách mở trang', () {
    testWidgets('tìm kiếm rồi tải được sản phẩm: không ghi vào lịch sử quét', (tester) async {
      final RecordingApi api = RecordingApi();
      final SessionHistory history = SessionHistory();
      await pumpFluwApp(tester, HomeScreen(apiService: api.service), history: history);

      await tester.enterText(find.byType(TextField), 'sữa chua');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Sữa chua'), findsOneWidget);
      expect(history.scans, isEmpty);
    });

    testWidgets('mở lại sản phẩm vừa quét: tải bằng mã vạch và đưa lên đầu lịch sử', (tester) async {
      final RecordingApi api = RecordingApi();
      final SessionHistory history = SessionHistory()
        ..addScan(_scan(sampleBarcode, 'Sữa chua'))
        ..addScan(_scan('2', 'Mới hơn'));
      await pumpFluwApp(tester, HomeScreen(apiService: api.service), history: history);

      await tester.tap(find.text('Sữa chua'));
      await tester.pumpAndSettle();

      expect(api.productRequests.single.path, endsWith('/$sampleBarcode'));
      expect(history.scans.first.barcode, sampleBarcode);
    });

    testWidgets('Home → Tài khoản → Lịch sử → Chi tiết dùng chung ApiService của Home', (tester) async {
      final RecordingApi api = RecordingApi();
      final SessionHistory history = SessionHistory()..addScan(_scan(sampleBarcode, 'Sữa chua'));
      await pumpFluwApp(tester, HomeScreen(apiService: api.service), history: history);

      await tester.tap(find.byTooltip('Tài khoản'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử quét'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      await tester.tap(find.text('Sữa chua'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(api.productRequests.single.path, endsWith('/$sampleBarcode'));
    });

    testWidgets('Home → Xem tất cả → Chi tiết dùng chung ApiService của Home', (tester) async {
      final RecordingApi api = RecordingApi();
      final SessionHistory history = SessionHistory()..addScan(_scan(sampleBarcode, 'Sữa chua'));
      await pumpFluwApp(tester, HomeScreen(apiService: api.service), history: history);

      await tester.tap(find.text('Xem tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sữa chua'));
      await tester.pumpAndSettle();

      expect(api.productRequests.single.path, endsWith('/$sampleBarcode'));
    });
  });

  group('mở màn quét', () {
    testWidgets('bấm hai lần trong cùng một khung hình chỉ mở một màn quét', (tester) async {
      FakeMobileScannerPlatform.install();
      await _pumpHome(tester);

      // Two taps landing in the same frame, before the navigator starts
      // absorbing pointers for the transition.
      final VoidCallback openScanner = tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!;
      openScanner();
      openScanner();
      await _waitForScannerTransition(tester);

      expect(find.byType(ScannerScreen, skipOffstage: false), findsOneWidget);
    });

    testWidgets('chọn "Nhập mã thủ công" thì quay về Home và con trỏ vào ô tìm kiếm', (tester) async {
      FakeMobileScannerPlatform.install();
      await _pumpHome(tester);

      await tester.tap(find.text('Quét mã vạch'));
      await _waitForScannerTransition(tester);
      await tester.tap(find.text('Nhập mã thủ công'));
      await tester.pumpAndSettle();

      expect(find.byType(ScannerScreen), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isTrue);
    });

    testWidgets('đóng màn quét rồi mở lại được', (tester) async {
      FakeMobileScannerPlatform.install();
      await _pumpHome(tester);

      await tester.tap(find.text('Quét mã vạch'));
      await _waitForScannerTransition(tester);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(find.byType(ScannerScreen), findsNothing);

      await tester.tap(find.text('Quét mã vạch'));
      await _waitForScannerTransition(tester);
      expect(find.byType(ScannerScreen), findsOneWidget);
    });
  });
}
