import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/widgets/scanner/manual_entry_button.dart';
import 'package:frontend/widgets/scanner/scan_detected_banner.dart';
import 'package:frontend/widgets/scanner/scanner_error_view.dart';
import 'package:frontend/widgets/scanner/scanner_top_bar.dart';
import 'package:frontend/widgets/scanner/scanner_viewfinder.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<void> _pump(WidgetTester tester, Widget child, {bool disableAnimations = false, ThemeMode mode = ThemeMode.light}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), disableAnimations: disableAnimations),
        child: Scaffold(backgroundColor: Colors.black, body: child),
      ),
    ),
  );
}

void main() {
  group('ScannerViewfinder', () {
    test('khung quét nằm giữa theo chiều ngang, hơi lệch lên trên', () {
      final Rect window = ScannerViewfinder.windowFor(const Size(390, 844));

      expect(window.size, ScannerViewfinder.windowSize);
      expect(window.center.dx, 195);
      expect(window.center.dy, closeTo(844 * 0.42, 0.01));
    });

    test('màn hẹp thì khung thu lại, vẫn chừa lề 24 px mỗi bên', () {
      final Rect window = ScannerViewfinder.windowFor(const Size(300, 600));

      expect(window.width, 252);
      expect(window.left, 24);
    });

    test('màn thấp (xoay ngang) thì khung thấp lại theo chiều cao', () {
      final Rect window = ScannerViewfinder.windowFor(const Size(800, 360));

      expect(window.height, closeTo(360 * ScannerViewfinder.maxHeightFraction, 0.01));
      expect(window.width, ScannerViewfinder.windowSize.width);
    });

    test('màn rất hẹp không làm lỗi, khung chỉ thu về 0', () {
      expect(ScannerViewfinder.windowFor(const Size(40, 600)).width, 0);
    });

    final Rect window = ScannerViewfinder.windowFor(const Size(390, 844));

    testWidgets('vạch quét chạy, và đứng yên khi giảm chuyển động', (tester) async {
      await _pump(tester, ScannerViewfinder(window: window));
      expect(tester.hasRunningAnimations, isTrue);

      await _pump(tester, ScannerViewfinder(window: window), disableAnimations: true);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('đã nhận mã thì vạch quét dừng', (tester) async {
      await _pump(tester, ScannerViewfinder(window: window));
      expect(tester.hasRunningAnimations, isTrue);

      await _pump(tester, ScannerViewfinder(window: window, animating: false));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('ScannerTopBar', () {
    testWidgets('bật/tắt đèn flash và đóng màn hình', (tester) async {
      int toggles = 0;
      int closes = 0;
      await _pump(
        tester,
        ScannerTopBar(torchState: TorchState.off, onClose: () => closes++, onToggleTorch: () => toggles++),
      );

      await tester.tap(find.byTooltip('Bật đèn flash'));
      await tester.tap(find.byTooltip('Đóng'));

      expect(toggles, 1);
      expect(closes, 1);
      expect(find.text('Quét mã vạch'), findsOneWidget);
    });

    testWidgets('đèn đang bật thì nút ghi "Tắt đèn flash"', (tester) async {
      await _pump(tester, ScannerTopBar(torchState: TorchState.on, onClose: () {}, onToggleTorch: () {}));

      expect(find.byTooltip('Tắt đèn flash'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('đèn tự động (iOS) được coi là đang bật', (tester) async {
      await _pump(tester, ScannerTopBar(torchState: TorchState.auto, onClose: () {}, onToggleTorch: () {}));

      expect(find.byTooltip('Đèn flash đang tự động, bấm để đổi'), findsOneWidget);
      expect(find.byIcon(Icons.flash_auto), findsOneWidget);
    });

    testWidgets('nút đèn là nút bật/tắt và tiêu đề là heading với trình đọc màn hình', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(tester, ScannerTopBar(torchState: TorchState.on, onClose: () {}, onToggleTorch: () {}));

      expect(
        tester.getSemantics(find.byTooltip('Tắt đèn flash')),
        matchesSemantics(
          tooltip: 'Tắt đèn flash',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Quét mã vạch')),
        matchesSemantics(label: 'Quét mã vạch', isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets('thiết bị không có đèn thì nút bị khóa', (tester) async {
      int toggles = 0;
      await _pump(
        tester,
        ScannerTopBar(torchState: TorchState.unavailable, onClose: () {}, onToggleTorch: () => toggles++),
      );

      await tester.tap(find.byTooltip('Đèn flash không khả dụng'), warnIfMissed: false);
      expect(toggles, 0);
    });
  });

  group('ScanDetectedBanner', () {
    for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('báo mã đã nhận và đang mở chi tiết (${mode.name})', (tester) async {
        await _pump(tester, const ScanDetectedBanner(barcode: '8934563138165'), mode: mode);

        expect(find.text('Đã nhận mã 8934563138165'), findsOneWidget);
        expect(find.text('Đang mở Chi tiết sản phẩm…'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    }

    testWidgets('trình đọc màn hình đọc mã từng chữ số, không đọc thành một số lớn', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(tester, const ScanDetectedBanner(barcode: '12345678'));

      expect(find.bySemanticsLabel(RegExp('Đã nhận mã 1 2 3 4 5 6 7 8')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('giảm chuyển động thì ẩn thanh tiến trình chạy liên tục', (tester) async {
      await _pump(tester, const ScanDetectedBanner(barcode: '12345678'), disableAnimations: true);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Đã nhận mã 12345678'), findsOneWidget);
    });
  });

  group('ScannerErrorView', () {
    testWidgets('chưa cấp quyền camera thì hướng dẫn bật trong Cài đặt', (tester) async {
      await _pump(tester, ScannerErrorView(errorCode: MobileScannerErrorCode.permissionDenied, onRetry: () {}));

      expect(find.text('Fluw chưa được phép dùng camera'), findsOneWidget);
      expect(find.textContaining('Cài đặt'), findsOneWidget);
    });

    testWidgets('chữ 200% trên vùng thấp vẫn cuộn được, không tràn', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pump(
        tester,
        SizedBox(
          height: 200,
          child: ScannerErrorView(errorCode: MobileScannerErrorCode.permissionDenied, onRetry: () {}),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsOneWidget);
    });

    testWidgets('nút "Thử lại" gọi lại camera', (tester) async {
      int retries = 0;
      await _pump(
        tester,
        ScannerErrorView(errorCode: MobileScannerErrorCode.genericError, onRetry: () => retries++),
      );

      await tester.tap(find.text('Thử lại'));
      expect(retries, 1);
    });

    testWidgets('thiết bị không hỗ trợ quét thì không hiện "Thử lại"', (tester) async {
      await _pump(tester, ScannerErrorView(errorCode: MobileScannerErrorCode.unsupported, onRetry: () {}));

      expect(find.text('Thử lại'), findsNothing);
    });

    test('mỗi loại lỗi có thông điệp riêng, không lộ chi tiết kỹ thuật', () {
      for (final MobileScannerErrorCode code in MobileScannerErrorCode.values) {
        final ({String title, String message}) text = ScannerErrorView.textFor(code);
        expect(text.title, isNotEmpty);
        expect(text.message, contains('nhập mã thủ công'));
        expect(text.message, isNot(contains(code.name)));
      }
    });
  });

  testWidgets('nút nhập mã thủ công gọi đúng hành động', (tester) async {
    int presses = 0;
    await _pump(tester, ManualEntryButton(onPressed: () => presses++));

    await tester.tap(find.text('Nhập mã thủ công'));
    expect(presses, 1);
  });
}
