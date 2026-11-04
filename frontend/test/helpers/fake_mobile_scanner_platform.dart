import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Stands in for the camera plugin so scanner screens can be driven in tests:
/// [emit] plays a detection, [startError] simulates a camera that fails to open.
class FakeMobileScannerPlatform extends MobileScannerPlatform {
  FakeMobileScannerPlatform({this.startError});

  final MobileScannerException? startError;
  final StreamController<BarcodeCapture?> _barcodes = StreamController<BarcodeCapture?>.broadcast();
  final StreamController<TorchState> _torchStates = StreamController<TorchState>.broadcast();

  int startCalls = 0;
  int stopCalls = 0;
  int torchToggles = 0;

  /// Installs a fake for the current test and restores the real plugin after it.
  static FakeMobileScannerPlatform install({MobileScannerException? startError}) {
    final MobileScannerPlatform original = MobileScannerPlatform.instance;
    final FakeMobileScannerPlatform fake = FakeMobileScannerPlatform(startError: startError);
    MobileScannerPlatform.instance = fake;
    addTearDown(() => MobileScannerPlatform.instance = original);
    return fake;
  }

  void emit(List<String?> rawValues) {
    _barcodes.add(BarcodeCapture(barcodes: [for (final String? value in rawValues) Barcode(rawValue: value)]));
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => _torchStates.stream;

  @override
  Stream<double> get zoomScaleStateStream => const Stream<double>.empty();

  @override
  Widget buildCameraView() => const ColoredBox(color: Color(0xFF2B2F2C));

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCalls++;
    final MobileScannerException? error = startError;
    if (error != null) throw error;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(1080, 1920),
    );
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> pause() async {}

  @override
  Future<void> toggleTorch() async => torchToggles++;

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> dispose() async {}
}
