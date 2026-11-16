import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/features/scan/presentation/barcode_camera_view.dart';

/// The camera that reads barcodes, behind an interface: widget tests cannot open a real camera.
abstract interface class BarcodeCamera {
  /// Runs only while [active]; calls [onDetected] with each code it reads.
  Widget build({required bool active, required ValueChanged<String> onDetected});
}

class LiveBarcodeCamera implements BarcodeCamera {
  const LiveBarcodeCamera();

  @override
  Widget build({required bool active, required ValueChanged<String> onDetected}) =>
      BarcodeCameraView(active: active, onDetected: onDetected);
}

final barcodeCameraProvider = Provider<BarcodeCamera>((ref) => const LiveBarcodeCamera());
