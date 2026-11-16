import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The live camera with ML Kit barcode reading, which runs on the phone and costs nothing. Only runs while [active]:
/// the scan tab stays mounted while other tabs or pages are shown, and a camera left on drains the battery.
class BarcodeCameraView extends StatefulWidget {
  const BarcodeCameraView({required this.active, required this.onDetected, super.key});

  final bool active;
  final ValueChanged<String> onDetected;

  @override
  State<BarcodeCameraView> createState() => _BarcodeCameraViewState();
}

class _BarcodeCameraViewState extends State<BarcodeCameraView> {
  // UPC-E is left out: its 8 digits use a different check-digit rule and it is rare on products sold in Vietnam.
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA],
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      unawaited(_run(_controller.start));
    }
  }

  @override
  void didUpdateWidget(BarcodeCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      unawaited(_run(widget.active ? _controller.start : _controller.stop));
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  /// Camera errors (no permission, no camera) are shown by the error builder; the call itself must not throw.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on MobileScannerException {
      // Shown by errorBuilder.
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.map((barcode) => barcode.rawValue).nonNulls.firstOrNull;
    if (widget.active && code != null) {
      widget.onDetected(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
      errorBuilder: (context, error) => _CameraError(error.errorCode),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError(this.code);

  final MobileScannerErrorCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = switch (code) {
      MobileScannerErrorCode.permissionDenied =>
        'Fluw chưa có quyền dùng camera. Hãy bật quyền Camera cho Fluw trong Cài đặt của máy, hoặc nhập mã bên dưới.',
      MobileScannerErrorCode.unsupported => 'Máy không có camera dùng được. Hãy nhập mã bên dưới.',
      _ => 'Không mở được camera. Hãy thử lại hoặc nhập mã bên dưới.',
    };
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ),
      ),
    );
  }
}
