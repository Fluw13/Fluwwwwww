import 'package:flutter/widgets.dart';
import 'package:fluw/features/scan/presentation/barcode_camera.dart';

/// Stands in for the camera: shows whether it would be running and lets a test "scan" a code.
class FakeBarcodeCamera implements BarcodeCamera {
  bool? isActive;
  ValueChanged<String>? _onDetected;

  void scan(String code) => _onDetected!(code);

  @override
  Widget build({required bool active, required ValueChanged<String> onDetected}) {
    isActive = active;
    _onDetected = onDetected;
    return Center(child: Text(active ? 'Camera đang chạy' : 'Camera đang tắt'));
  }
}
