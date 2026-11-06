import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/history/session_history.dart';
import 'package:frontend/core/search/search_input.dart';
import 'package:frontend/screens/account_screen.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/product_detail_screen.dart';
import 'package:frontend/screens/scanner_screen.dart';
import 'package:frontend/screens/search_results_screen.dart';
import 'package:frontend/widgets/home/zero_intro_card.dart';
import 'package:frontend/widgets/product/product_card.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_backend.dart';
import '../helpers/fake_mobile_scanner_platform.dart';
import '../helpers/fluw_app_harness.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  SessionHistory? history,
  FakeBackend? backend,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return pumpFluwApp(
    tester,
    const HomeScreen(),
    history: history,
    client: (backend ?? productBackend()).client,
    themeMode: themeMode,
  );
}

Future<void> _submit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

Future<void> _waitForScannerTransition(WidgetTester tester) async {
  await tester.pump();
  // The scan line repeats forever, so wait for the route transition only.
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'lần đầu mở: lời chào, ô tìm kiếm, giới thiệu Zero, nút quét, nút tài khoản (${mode.name})',
      (tester) async {
        await _pumpHome(tester, themeMode: mode);

        expect(find.text('Bạn đang ăn món gì?'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(ZeroIntroCard), findsOneWidget);
        expect(find.text('Quét mã vạch'), findsOneWidget);
        expect(find.byTooltip('Tài khoản'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  group('tìm kiếm', () {
    testWidgets(
      'gõ chữ không gửi gì; bấm tìm thì lưu từ khóa và mở màn kết quả, tìm đúng một lần',
      (tester) async {
        final FakeBackend backend = productBackend();
        final SessionHistory history = SessionHistory();
        await _pumpHome(tester, history: history, backend: backend);

        await tester.enterText(find.byType(TextField), 'H');
        await tester.enterText(find.byType(TextField), 'Hảo hảo');
        await tester.pump();
        expect(backend.searchRequests, isEmpty);

        await _submit(tester, '  Hảo hảo  ');

        expect(history.searches, ['Hảo hảo']);
        expect(find.byType(SearchResultsScreen), findsOneWidget);
        expect(find.text('Mỳ Hảo Hảo'), findsOneWidget);
        expect(backend.searchRequests.single.queryParameters['q'], 'Hảo hảo');
        expect(backend.productRequests, isEmpty);
      },
    );

    testWidgets(
      'mã vạch 13 số (có khoảng trắng): mở thẳng chi tiết v1, không tìm, không ghi lịch sử quét',
      (tester) async {
        final FakeBackend backend = productBackend();
        final SessionHistory history = SessionHistory();
        await _pumpHome(tester, history: history, backend: backend);

        await _submit(tester, ' 893 0000 000019 ');

        expect(find.byType(ProductDetailScreen), findsOneWidget);
        expect(find.text('Bánh quy bơ (dữ liệu thử)'), findsOneWidget);
        expect(
          backend.productRequests.single.path,
          '/api/v1/products/$sampleBarcode',
        );
        expect(backend.searchRequests, isEmpty);
        expect(history.searches, ['893 0000 000019']);
        expect(history.scans, isEmpty);
      },
    );

    for (final String digits in [
      '333',
      '1234567',
      '1234567890',
      '123456789012345',
    ]) {
      testWidgets(
        'toàn chữ số nhưng không dài 8/12/13/14 ("$digits"): tìm theo tên như từ khóa thường',
        (tester) async {
          final FakeBackend backend = productBackend();
          await _pumpHome(tester, backend: backend);

          await _submit(tester, digits);

          expect(find.byType(SearchResultsScreen), findsOneWidget);
          expect(backend.searchRequests.single.queryParameters['q'], digits);
          expect(backend.productRequests, isEmpty);
        },
      );
    }

    for (final (String text, String message) in [
      ('a', SearchInput.tooShortMessage),
      ('!!', SearchInput.noLetterMessage),
    ]) {
      testWidgets(
        '"$text": báo ngay dưới ô nhập, không gửi, không lưu lịch sử',
        (tester) async {
          final FakeBackend backend = productBackend();
          final SessionHistory history = SessionHistory();
          await _pumpHome(tester, history: history, backend: backend);

          await tester.enterText(find.byType(TextField), text);
          await tester.tap(find.byTooltip('Tìm'));
          await tester.pumpAndSettle();

          expect(find.text(message), findsOneWidget);
          expect(find.byType(SearchResultsScreen), findsNothing);
          expect(backend.paths, ['/health']);
          expect(history.searches, isEmpty);
        },
      );
    }

    testWidgets('ô tìm kiếm trống thì không làm gì', (tester) async {
      final SessionHistory history = SessionHistory();
      await _pumpHome(tester, history: history);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byTooltip('Tìm'));
      await tester.pumpAndSettle();

      expect(history.searches, isEmpty);
      expect(find.byType(SearchResultsScreen), findsNothing);
      expect(find.byType(ProductDetailScreen), findsNothing);
    });

    testWidgets('bấm từ khóa gần đây thì tìm lại theo cùng quy tắc', (
      tester,
    ) async {
      final FakeBackend backend = productBackend();
      final SessionHistory history = SessionHistory()..addSearch('mì hảo hảo');
      await _pumpHome(tester, history: history, backend: backend);

      await tester.tap(find.widgetWithText(ActionChip, 'mì hảo hảo'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchResultsScreen), findsOneWidget);
      expect(backend.searchRequests.single.queryParameters['q'], 'mì hảo hảo');
    });
  });

  testWidgets(
    'có lịch sử thì hiện từ khóa gần đây và sản phẩm vừa quét thay cho giới thiệu',
    (tester) async {
      final SessionHistory history = SessionHistory()
        ..addSearch('mì hảo hảo')
        ..addScan(sampleSummary(barcode: '1', name: 'Sản phẩm 1'))
        ..addScan(sampleSummary(barcode: '2', name: 'Sản phẩm 2'))
        ..addScan(sampleSummary(barcode: '3', name: 'Sản phẩm 3'))
        ..addScan(sampleSummary(barcode: '4', name: 'Sản phẩm 4'));
      await _pumpHome(tester, history: history);

      expect(find.widgetWithText(ActionChip, 'mì hảo hảo'), findsOneWidget);
      expect(find.byType(ZeroIntroCard), findsNothing);
      expect(find.text('Vừa quét'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(3));
      expect(
        find.text('Sản phẩm 4'),
        findsOneWidget,
        reason: 'mới nhất lên đầu',
      );
      expect(find.text('Sản phẩm 1'), findsNothing);
    },
  );

  testWidgets('lịch sử thay đổi thì Home cập nhật ngay', (tester) async {
    final SessionHistory history = SessionHistory();
    await _pumpHome(tester, history: history);
    expect(find.byType(ProductCard), findsNothing);

    history.addScan(sampleSummary(name: 'Mì Hảo Hảo'));
    await tester.pump();

    expect(find.text('Mì Hảo Hảo'), findsOneWidget);
  });

  testWidgets('nút tài khoản mở màn Tài khoản', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byTooltip('Tài khoản'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
  });

  testWidgets(
    'màn 320 px với chữ 200% không tràn, kể cả khi có lịch sử và lỗi ô nhập',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final SessionHistory history = SessionHistory()
        ..addSearch('một từ khóa tìm kiếm khá dài để thử')
        ..addScan(
          sampleSummary(
            barcode: '1',
            name: 'Bánh quy yến mạch nguyên hạt vị mật ong hộp lớn',
          ),
        );
      await _pumpHome(tester, history: history);
      expect(tester.takeException(), isNull);

      // With 200% text the field starts below the part of the list that is
      // built, so scroll the page down to it first.
      await tester.scrollUntilVisible(
        find.byType(TextField),
        100,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(find.byType(TextField), 'a');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(find.text(SearchInput.tooShortMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('lịch sử theo cách mở trang', () {
    testWidgets('tìm rồi mở sản phẩm từ kết quả: không ghi vào lịch sử quét', (
      tester,
    ) async {
      final FakeBackend backend = productBackend();
      final SessionHistory history = SessionHistory();
      await _pumpHome(tester, history: history, backend: backend);

      await _submit(tester, 'Hảo hảo');
      await tester.tap(find.text('Mỳ Hảo Hảo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(history.scans, isEmpty);
    });

    testWidgets(
      'mở lại sản phẩm vừa quét: tải bằng mã vạch và đưa lên đầu lịch sử',
      (tester) async {
        final FakeBackend backend = productBackend();
        final SessionHistory history = SessionHistory()
          ..addScan(sampleSummary(name: 'Sữa chua'))
          ..addScan(sampleSummary(barcode: '2', name: 'Mới hơn'));
        await _pumpHome(tester, history: history, backend: backend);

        await tester.tap(find.text('Sữa chua'));
        await tester.pumpAndSettle();

        expect(
          backend.productRequests.single.path,
          '/api/v1/products/$sampleBarcode',
        );
        expect(history.scans.first.barcode, sampleBarcode);
        expect(
          history.scans.first.name,
          'Bánh quy bơ (dữ liệu thử)',
          reason: 'cập nhật từ dữ liệu vừa tải',
        );
      },
    );

    testWidgets(
      'Home → Tài khoản → Lịch sử → Chi tiết dùng chung client API của app',
      (tester) async {
        final FakeBackend backend = productBackend();
        final SessionHistory history = SessionHistory()
          ..addScan(sampleSummary(name: 'Sữa chua'));
        await _pumpHome(tester, history: history, backend: backend);

        await tester.tap(find.byTooltip('Tài khoản'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lịch sử quét'));
        await tester.pumpAndSettle();
        expect(find.byType(HistoryScreen), findsOneWidget);

        await tester.tap(find.text('Sữa chua'));
        await tester.pumpAndSettle();

        expect(find.byType(ProductDetailScreen), findsOneWidget);
        expect(
          backend.productRequests.single.path,
          '/api/v1/products/$sampleBarcode',
        );
      },
    );

    testWidgets('Home → Xem tất cả → Chi tiết dùng chung client API của app', (
      tester,
    ) async {
      final FakeBackend backend = productBackend();
      final SessionHistory history = SessionHistory()
        ..addScan(sampleSummary(name: 'Sữa chua'));
      await _pumpHome(tester, history: history, backend: backend);

      await tester.tap(find.text('Xem tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sữa chua'));
      await tester.pumpAndSettle();

      expect(
        backend.productRequests.single.path,
        '/api/v1/products/$sampleBarcode',
      );
    });
  });

  group('mở màn quét', () {
    testWidgets('bấm hai lần trong cùng một khung hình chỉ mở một màn quét', (
      tester,
    ) async {
      FakeMobileScannerPlatform.install();
      await _pumpHome(tester);

      // Two taps landing in the same frame, before the navigator starts
      // absorbing pointers for the transition.
      final VoidCallback openScanner = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      openScanner();
      openScanner();
      await _waitForScannerTransition(tester);

      expect(find.byType(ScannerScreen, skipOffstage: false), findsOneWidget);
    });

    testWidgets(
      'chọn "Nhập mã thủ công" thì quay về Home và con trỏ vào ô tìm kiếm',
      (tester) async {
        FakeMobileScannerPlatform.install();
        await _pumpHome(tester);

        await tester.tap(find.text('Quét mã vạch'));
        await _waitForScannerTransition(tester);
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
