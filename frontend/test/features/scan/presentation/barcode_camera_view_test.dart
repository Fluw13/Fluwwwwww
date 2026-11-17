import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/scan/presentation/barcode_camera_view.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Behaves like mobile_scanner's controller where it matters: a stop that comes while the camera is still starting is
/// ignored, and a refused permission ends the start with an error.
class _FakeController extends MobileScannerController {
  _FakeController() : super(autoStart: false);

  final StreamController<BarcodeCapture> captures = StreamController<BarcodeCapture>.broadcast();
  int starts = 0;
  int stops = 0;
  Completer<void>? startGate;
  bool refusePermission = false;

  MobileScannerState _state({bool starting = false, bool running = false, MobileScannerException? error}) =>
      MobileScannerState(
        availableCameras: 1,
        cameraDirection: CameraFacing.back,
        cameraLensType: CameraLensType.any,
        isInitialized: !starting,
        isStarting: starting,
        isRunning: running,
        size: const Size(100, 100),
        torchState: TorchState.unavailable,
        zoomScale: 1,
        deviceOrientation: DeviceOrientation.portraitUp,
        error: error,
      );

  @override
  Stream<BarcodeCapture> get barcodes => captures.stream;

  @override
  Future<void> start({CameraFacing? cameraDirection, CameraLensType? cameraLensType}) async {
    starts++;
    value = _state(starting: true);
    await startGate?.future;
    if (refusePermission) {
      const error = MobileScannerException(errorCode: MobileScannerErrorCode.permissionDenied);
      value = _state(error: error);
      throw error;
    }
    value = _state(running: true);
  }

  @override
  Future<void> stop() async {
    stops++;
    if (!value.isStarting) {
      value = _state();
    }
  }

  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);
}

void main() {
  late _FakeController controller;
  final detected = <String>[];

  setUp(() {
    controller = _FakeController();
    detected.clear();
    // In debug builds MobileScanner first force-stops the native scanner (a hot-restart guard); nothing to answer here.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
      (call) async => null,
    );
    addTearDown(controller.captures.close);
  });

  Future<void> pumpView(WidgetTester tester, {required bool active}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BarcodeCameraView(active: active, onDetected: detected.add, controller: controller),
        ),
      ),
    );
    await tester.pump();
  }

  void lifecycle(WidgetTester tester, List<AppLifecycleState> states) {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('bật khi active, tắt khi hết active; mã chỉ được báo khi đang active', (tester) async {
    await pumpView(tester, active: true);
    expect(controller.value.isRunning, isTrue);

    controller.captures.add(const BarcodeCapture(barcodes: [Barcode(rawValue: '8934673607827')]));
    await tester.pump();
    expect(detected, ['8934673607827']);

    await pumpView(tester, active: false);
    expect(controller.value.isRunning, isFalse);
    controller.captures.add(const BarcodeCapture(barcodes: [Barcode(rawValue: '96385074')]));
    await tester.pump();
    expect(detected, hasLength(1), reason: 'khung hình cuối gửi tới sau khi rời tab không được mở sản phẩm');
  });

  testWidgets('rời tab khi camera còn đang mở: mở xong thì tắt ngay, không để camera chạy ngầm', (tester) async {
    controller.startGate = Completer<void>();
    await pumpView(tester, active: true);
    await pumpView(tester, active: false);
    expect(controller.value.isStarting, isTrue, reason: 'lệnh tắt lúc đang mở bị camera bỏ qua');

    controller.startGate!.complete();
    await tester.pump();
    await tester.pump();

    expect(controller.value.isRunning, isFalse);
    expect(controller.stops, greaterThanOrEqualTo(1));
  });

  testWidgets('app mờ đi thì tắt, quay lại thì bật; chưa có quyền camera thì không bật lại theo vòng đời app', (
    tester,
  ) async {
    await pumpView(tester, active: true);
    lifecycle(tester, [AppLifecycleState.inactive]);
    await tester.pump();
    expect(controller.value.isRunning, isFalse);
    lifecycle(tester, [AppLifecycleState.resumed]);
    await tester.pump();
    expect(controller.value.isRunning, isTrue);
  });

  testWidgets(
    'đang hỏi quyền camera (app mờ đi vì hộp thoại): cho phép xong thì camera chạy luôn, không tắt rồi bật lại',
    (tester) async {
      controller.startGate = Completer<void>();
      await pumpView(tester, active: true);

      lifecycle(tester, [AppLifecycleState.inactive]);
      controller.startGate!.complete();
      await tester.pump();
      lifecycle(tester, [AppLifecycleState.resumed]);
      await tester.pump();

      expect(controller.value.isRunning, isTrue);
      expect((controller.starts, controller.stops), (1, 0));
    },
  );

  testWidgets('bị từ chối quyền camera: không hỏi lại khi quay lại app hay đổi tab; "Thử lại" thì hỏi lại', (
    tester,
  ) async {
    controller.refusePermission = true;
    await pumpView(tester, active: true);
    expect(controller.starts, 1);
    expect(find.textContaining('chưa có quyền dùng camera'), findsOneWidget);

    lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    await pumpView(tester, active: false);
    await pumpView(tester, active: true);
    expect(controller.starts, 1, reason: 'Android trước 11 sẽ hỏi mãi nếu tự bật lại');

    controller.refusePermission = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(controller.starts, 2);
    expect(controller.value.isRunning, isTrue);
  });
}
