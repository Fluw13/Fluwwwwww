import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The live camera with ML Kit barcode reading, which runs on the phone and costs nothing. Only runs while [active]:
/// the scan tab stays mounted while other tabs or pages are shown, and a camera left on drains the battery.
class BarcodeCameraView extends StatefulWidget {
  const BarcodeCameraView({required this.active, required this.onDetected, this.controller, super.key});

  final bool active;
  final ValueChanged<String> onDetected;

  /// For tests; the app lets the view make its own.
  final MobileScannerController? controller;

  @override
  State<BarcodeCameraView> createState() => _BarcodeCameraViewState();
}

class _BarcodeCameraViewState extends State<BarcodeCameraView> with WidgetsBindingObserver {
  // UPC-E is left out: its 8 digits use a different check-digit rule and it is rare on products sold in Vietnam.
  late final MobileScannerController _controller =
      widget.controller ??
      MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA],
      );
  bool _settling = false;
  bool _settleAgain = false;
  bool _foreground = true;

  /// After the user refuses the camera, it is only tried again from "Thử lại": starting it again on every return to
  /// the app would ask again and again (Android before 11 keeps asking until "Don't ask again").
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_settle());
  }

  /// mobile_scanner's own rule for a controller the app owns: off when the app goes inactive (the last state in which
  /// frames still run, so the call is not left waiting), on again when it is back. Skipped while the camera permission
  /// is not granted: the permission dialog itself makes the app inactive, and restarting after it would ask again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed || AppLifecycleState.inactive:
        _foreground = state == AppLifecycleState.resumed;
        unawaited(_settle());
      case AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didUpdateWidget(BarcodeCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      unawaited(_settle());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) {
      unawaited(_controller.dispose());
    }
    super.dispose();
  }

  /// One call at a time, then a look at the newest wish: mobile_scanner ignores a stop that comes while it is still
  /// starting, so leaving the tab right after opening it would otherwise leave the camera on.
  Future<void> _settle() async {
    if (_settling) {
      _settleAgain = true;
      return;
    }
    _settling = true;
    try {
      do {
        _settleAgain = false;
        await _settleOnce();
      } while (_settleAgain && mounted);
    } finally {
      _settling = false;
    }
  }

  Future<void> _settleOnce() async {
    if (!mounted) {
      return;
    }
    final wanted = widget.active && _foreground && !_permissionDenied;
    if (wanted == _controller.value.isRunning) {
      return;
    }
    try {
      await (wanted ? _controller.start() : _controller.stop());
    } on MobileScannerException catch (error) {
      // Shown by errorBuilder; a refusal also stops the automatic restarts.
      if (error.errorCode == MobileScannerErrorCode.permissionDenied && mounted) {
        setState(() => _permissionDenied = true);
      }
    }
  }

  void _retry() {
    setState(() => _permissionDenied = false);
    unawaited(_settle());
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
      errorBuilder: (context, error) => _CameraError(error.errorCode, onRetry: _retry),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError(this.code, {required this.onRetry});

  final MobileScannerErrorCode code;
  final VoidCallback onRetry;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              if (code != MobileScannerErrorCode.unsupported) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
