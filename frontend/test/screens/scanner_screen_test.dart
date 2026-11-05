import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/scanner/scanner_exit.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/api/fluw_api_client.dart';
import 'package:frontend/data/api/fluw_api_scope.dart';
import 'package:frontend/screens/product_detail_screen.dart';
import 'package:frontend/screens/scanner_screen.dart';
import 'package:frontend/widgets/scanner/scanner_viewfinder.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../helpers/fake_backend.dart';
import '../helpers/fake_mobile_scanner_platform.dart';

const String _barcode = '8934563138165';

/// The product page opened after a scan gets "not found", which is enough to
/// prove the navigation.
FluwApiClient _api() =>
    FakeBackend(product: (_) => FakeBackend.fixture('error-product-not-found'))
        .client;

/// Opens the scanner on top of a stand-in home page; [onExit] receives what the
/// scanner hands back when its route completes.
Future<void> _pumpHomeWithScanner(
  WidgetTester tester,
  FluwApiClient api,
  void Function(ScannerExit?) onExit,
) async {
  await tester.pumpWidget(
    FluwApiScope(
      client: api,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onExit(
                await Navigator.push<ScannerExit>(
                  context,
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                ),
              );
            },
            child: const Text('Trang chủ'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Trang chủ'));
  await tester.pump();
  // The scan line repeats forever, so wait for the route transition only.
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets(
    'camera mở: hiện khung quét, hướng dẫn, thanh trên và nút nhập tay',
    (tester) async {
      final FakeMobileScannerPlatform camera =
          FakeMobileScannerPlatform.install();
      await tester.pumpWidget(
        FluwApiScope(
          client: _api(),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const ScannerScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(camera.startCalls, 1);
      expect(find.text('Đưa mã vạch vào trong khung'), findsOneWidget);
      expect(find.text('Quét mã vạch'), findsOneWidget);
      expect(find.byTooltip('Đóng'), findsOneWidget);
      expect(find.text('Nhập mã thủ công'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nhận mã: báo đã nhận, dừng camera, rồi thay bằng trang chi tiết',
    (tester) async {
      final FakeMobileScannerPlatform camera =
          FakeMobileScannerPlatform.install();
      await _pumpHomeWithScanner(tester, _api(), (_) {});

      camera.emit(['https://example.com', _barcode]);
      await tester.pump();

      expect(find.text('Đã nhận mã $_barcode'), findsOneWidget);
      expect(camera.stopCalls, greaterThanOrEqualTo(1));

      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.byType(ScannerScreen), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsOneWidget);
    },
  );

  testWidgets(
    'mã không phải sản phẩm (URL, chữ) thì bỏ qua, vẫn tiếp tục quét',
    (tester) async {
      final FakeMobileScannerPlatform camera =
          FakeMobileScannerPlatform.install();
      await tester.pumpWidget(
        FluwApiScope(
          client: _api(),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const ScannerScreen(),
          ),
        ),
      );
      await tester.pump();

      camera.emit(['https://example.com/$_barcode', 'xin chào', null]);
      await tester.pump();

      expect(find.textContaining('Đã nhận mã'), findsNothing);
      expect(camera.stopCalls, 0);
      expect(find.text('Đưa mã vạch vào trong khung'), findsOneWidget);
    },
  );

  testWidgets('đọc được nhiều lần liên tiếp chỉ mở một trang chi tiết', (
    tester,
  ) async {
    final FakeMobileScannerPlatform camera =
        FakeMobileScannerPlatform.install();
    await _pumpHomeWithScanner(tester, _api(), (_) {});

    camera
      ..emit([_barcode])
      ..emit(['12345678']);
    await tester.pump();

    expect(
      find.text('Đã nhận mã $_barcode', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Đã nhận mã 12345678', skipOffstage: false), findsNothing);
    expect(camera.stopCalls, 1);

    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.byType(ScannerScreen), findsNothing);
  });

  testWidgets('đã nhận mã thì Đóng, Nhập tay và nút Back không còn tác dụng', (
    tester,
  ) async {
    final FakeMobileScannerPlatform camera =
        FakeMobileScannerPlatform.install();
    ScannerExit? exit;
    bool closed = false;
    await _pumpHomeWithScanner(tester, _api(), (value) {
      closed = true;
      exit = value;
    });

    camera.emit([_barcode]);
    await tester.idle();

    // The frame with the confirmation has not been drawn yet, so the buttons
    // still carry their callbacks: they must refuse to act.
    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
        .onPressed!();
    tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed!();

    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(
      closed,
      isTrue,
      reason: 'pushReplacement completes the scanner route',
    );
    expect(exit, isNull);
  });

  testWidgets('chưa cấp quyền camera: hướng dẫn bật quyền, vẫn nhập tay được', (
    tester,
  ) async {
    FakeMobileScannerPlatform.install(
      startError: const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      ),
    );
    ScannerExit? exit;
    await _pumpHomeWithScanner(tester, _api(), (value) => exit = value);

    expect(find.text('Fluw chưa được phép dùng camera'), findsOneWidget);
    expect(find.text('Đưa mã vạch vào trong khung'), findsNothing);

    await tester.tap(find.text('Nhập mã thủ công'));
    await tester.pumpAndSettle();
    expect(exit, ScannerExit.manualEntry);
  });

  testWidgets('ứng dụng vào nền thì tắt camera, quay lại thì bật lại', (
    tester,
  ) async {
    final FakeMobileScannerPlatform camera =
        FakeMobileScannerPlatform.install();
    await tester.pumpWidget(
      FluwApiScope(
        client: _api(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ScannerScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(camera.startCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(camera.stopCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(camera.startCalls, 2);
  });

  testWidgets('bấm "Nhập mã thủ công" đóng màn quét và báo về màn trước', (
    tester,
  ) async {
    FakeMobileScannerPlatform.install();
    ScannerExit? exit;
    await _pumpHomeWithScanner(tester, _api(), (value) => exit = value);

    await tester.tap(find.text('Nhập mã thủ công'));
    await tester.pumpAndSettle();

    expect(exit, ScannerExit.manualEntry);
    expect(find.byType(ScannerScreen), findsNothing);
  });

  testWidgets('màn 320 px với chữ 200% không tràn', (tester) async {
    FakeMobileScannerPlatform.install();
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      FluwApiScope(
        client: _api(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ScannerScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  group('chống thao tác chồng nhau', () {
    testWidgets('đã nhận mã thì không cho Back và vạch quét dừng', (
      tester,
    ) async {
      final FakeMobileScannerPlatform camera =
          FakeMobileScannerPlatform.install();
      await _pumpHomeWithScanner(tester, _api(), (_) {});

      camera.emit([_barcode]);
      await tester.pump();

      final PopScope<Object?> popScope = tester.widget(
        find.byWidgetPredicate(
          (widget) => widget is PopScope,
          skipOffstage: false,
        ),
      );
      expect(popScope.canPop, isFalse);
      expect(
        tester
            .widget<ScannerViewfinder>(
              find.byType(ScannerViewfinder, skipOffstage: false),
            )
            .animating,
        isFalse,
      );
      await tester.pumpAndSettle();
    });

    testWidgets(
      'đọc được mã trong lúc màn quét đang đóng thì bỏ qua, không bật lại camera',
      (tester) async {
        final FakeMobileScannerPlatform camera =
            FakeMobileScannerPlatform.install();
        await _pumpHomeWithScanner(tester, _api(), (_) {});

        await tester.tap(find.byTooltip('Đóng'));
        await tester.pump();
        camera.emit([_barcode]);
        await tester.pump();

        expect(
          find.textContaining('Đã nhận mã', skipOffstage: false),
          findsNothing,
        );

        await tester.pumpAndSettle();

        expect(find.byType(ProductDetailScreen), findsNothing);
        expect(find.text('Trang chủ'), findsOneWidget);
        expect(camera.startCalls, 1);
      },
    );

    testWidgets(
      'Back hệ thống trong cùng khung hình với lúc nhận mã: về Home, không mở chi tiết',
      (tester) async {
        final FakeMobileScannerPlatform camera =
            FakeMobileScannerPlatform.install();
        await _pumpHomeWithScanner(tester, _api(), (_) {});

        camera.emit([_barcode]);
        await tester.idle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ProductDetailScreen), findsNothing);
        expect(find.text('Trang chủ'), findsOneWidget);
        expect(camera.startCalls, 1);
      },
    );
  });

  group('vòng đời và quyền camera', () {
    testWidgets('đã nhận mã thì vào nền / quay lại không bật lại camera', (
      tester,
    ) async {
      final FakeMobileScannerPlatform camera =
          FakeMobileScannerPlatform.install();
      await _pumpHomeWithScanner(tester, _api(), (_) {});

      camera.emit([_barcode]);
      await tester.idle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(camera.startCalls, 1);
    });

    testWidgets(
      'chưa có quyền camera thì quay lại app không tự hỏi lại, chỉ khi bấm "Thử lại"',
      (tester) async {
        final FakeMobileScannerPlatform camera =
            FakeMobileScannerPlatform.install(
              startError: const MobileScannerException(
                errorCode: MobileScannerErrorCode.permissionDenied,
              ),
            );
        await tester.pumpWidget(
          FluwApiScope(
            client: _api(),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const ScannerScreen(),
            ),
          ),
        );
        await tester.pump();
        expect(camera.startCalls, 1);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(camera.startCalls, 1);

        await tester.tap(find.text('Thử lại'));
        await tester.pump();
        expect(camera.startCalls, 2);
      },
    );
  });

  group('bố cục', () {
    for (final Size size in [const Size(320, 568), const Size(640, 360)]) {
      testWidgets(
        'đã nhận mã, chữ 200%, màn ${size.width.toInt()}×${size.height.toInt()}: không tràn',
        (tester) async {
          final FakeMobileScannerPlatform camera =
              FakeMobileScannerPlatform.install();
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await tester.pumpWidget(
            FluwApiScope(
              client: _api(),
              child: MaterialApp(
                theme: AppTheme.light(),
                home: const ScannerScreen(),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);

          camera.emit([_barcode]);
          await tester.idle();
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
        },
      );
    }

    testWidgets('lỗi camera, chữ 200%, màn 320×568: không tràn', (
      tester,
    ) async {
      FakeMobileScannerPlatform.install(
        startError: const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        FluwApiScope(
          client: _api(),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const ScannerScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'chữ 200% trên màn 320×568: dòng hướng dẫn không đè lên nút nhập tay',
      (tester) async {
        FakeMobileScannerPlatform.install();
        tester.view
          ..physicalSize = const Size(320, 568)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          FluwApiScope(
            client: _api(),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const ScannerScreen(),
            ),
          ),
        );
        await tester.pump();

        final Finder hint = find.text('Đưa mã vạch vào trong khung');
        if (hint.evaluate().isNotEmpty) {
          expect(
            tester.getRect(hint).bottom,
            lessThan(tester.getRect(find.text('Nhập mã thủ công')).top),
          );
        }
      },
    );

    testWidgets(
      'màn xoay ngang thấp thì bỏ dòng hướng dẫn thay vì đè lên nút nhập tay',
      (tester) async {
        FakeMobileScannerPlatform.install();
        tester.view
          ..physicalSize = const Size(800, 360)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          FluwApiScope(
            client: _api(),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const ScannerScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Đưa mã vạch vào trong khung'), findsNothing);
        expect(find.text('Nhập mã thủ công'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
