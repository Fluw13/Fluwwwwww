import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/navigation/product_origin.dart';
import '../core/scanner/barcode_picker.dart';
import '../core/scanner/scanner_exit.dart';
import '../core/theme/app_spacing.dart';
import '../services/api_service.dart';
import '../widgets/scanner/manual_entry_button.dart';
import '../widgets/scanner/scan_detected_banner.dart';
import '../widgets/scanner/scanner_error_view.dart';
import '../widgets/scanner/scanner_hint.dart';
import '../widgets/scanner/scanner_top_bar.dart';
import '../widgets/scanner/scanner_viewfinder.dart';
import 'product_detail_screen.dart';

/// Camera chrome stays dark in both themes: it sits on top of a live preview.
/// Once a code is read the screen is locked (no close, back or manual entry)
/// until it has been replaced by the product page.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.apiService});

  /// Passed on to the product page; owned by the caller.
  final ApiService? apiService;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  /// With very large text the bottom controls scroll instead of pushing the
  /// top bar off screen.
  static const double _bottomMaxHeightFactor = 0.6;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  String? _detectedBarcode;

  bool get _hasDetected => _detectedBarcode != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runSafely(_controller.dispose());
    super.dispose();
  }

  /// MobileScanner only follows the app lifecycle when it owns its controller,
  /// so the camera is released here while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_hasDetected || !_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _runSafely(_controller.start());
      case AppLifecycleState.inactive:
        _runSafely(_controller.stop());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
    }
  }

  void _runSafely(Future<void> action) {
    unawaited(action.catchError((Object error) => debugPrint('Scanner: $error')));
  }

  bool get _isOnTop => mounted && ModalRoute.isCurrentOf(context) == true;

  void _onDetect(BarcodeCapture capture) {
    // A code read while the screen is closing (or covered) is ignored.
    if (_hasDetected || !_isOnTop) return;

    final String? barcode = firstProductBarcode(capture.barcodes.map((code) => code.rawValue));
    if (barcode == null) return;

    setState(() => _detectedBarcode = barcode);
    unawaited(HapticFeedback.mediumImpact());
    _runSafely(_controller.stop());

    // Navigate after this frame so the confirmation is drawn first; it then
    // stays visible underneath while the product page fades in.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openProduct(barcode));
  }

  /// The screen may have been popped in the same frame as the detection; then
  /// it is on its way out and must neither navigate nor restart the camera.
  void _openProduct(String barcode) {
    if (!_isOnTop) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(query: barcode, origin: ProductOrigin.scan, apiService: widget.apiService),
      ),
    );
  }

  void _close() {
    if (!_hasDetected) Navigator.pop(context);
  }

  void _manualEntry() {
    if (!_hasDetected) Navigator.pop(context, ScannerExit.manualEntry);
  }

  void _toggleTorch() => _runSafely(_controller.toggleTorch());

  void _retryCamera() => _runSafely(_controller.start());

  @override
  Widget build(BuildContext context) {
    final String? detected = _detectedBarcode;

    return PopScope(
      canPop: detected == null,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final Rect window = ScannerViewfinder.windowFor(constraints.biggest);

              return Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    scanWindow: window,
                    errorBuilder: (context, error) => const ColoredBox(color: Colors.black),
                    overlayBuilder: (context, _) => _PreviewOverlay(
                      window: window,
                      area: constraints.biggest,
                      scanning: detected == null,
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, safeArea) => ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _controller,
                        builder: (context, state, _) {
                          final MobileScannerException? error = state.error;

                          return Column(
                            children: [
                              ScannerTopBar(
                                torchState: state.torchState,
                                onClose: detected == null ? _close : null,
                                onToggleTorch: detected == null ? _toggleTorch : null,
                              ),
                              Expanded(
                                child: error == null
                                    ? const SizedBox.shrink()
                                    : ScannerErrorView(errorCode: error.errorCode, onRetry: _retryCamera),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: safeArea.maxHeight * _bottomMaxHeightFactor),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.screenPadding,
                                    AppSpacing.md,
                                    AppSpacing.screenPadding,
                                    AppSpacing.xxl,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (detected != null) ...[
                                        ScanDetectedBanner(barcode: detected),
                                        const SizedBox(height: AppSpacing.md),
                                      ],
                                      ManualEntryButton(onPressed: detected == null ? _manualEntry : null),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Drawn only while the camera preview is visible (not over the error view).
class _PreviewOverlay extends StatelessWidget {
  const _PreviewOverlay({required this.window, required this.area, required this.scanning});

  /// Space the hint needs under the frame, and space kept for the bottom
  /// controls. On short (landscape) screens the hint is dropped rather than
  /// drawn over the "Nhập mã thủ công" button.
  static const double _hintGap = AppSpacing.xl;
  static const double _hintHeightAtNormalText = 48;
  static const double _bottomControlsRoom = 120;

  final Rect window;
  final Size area;
  final bool scanning;

  bool _hasRoomForHint(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double hintBottom = window.bottom + _hintGap + scaler.scale(_hintHeightAtNormalText);
    return hintBottom < area.height - scaler.scale(_bottomControlsRoom);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ScannerViewfinder(window: window, animating: scanning),
        if (scanning && _hasRoomForHint(context))
          Positioned(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: window.bottom + AppSpacing.xl,
            child: const ScannerHint(text: 'Đưa mã vạch vào trong khung'),
          ),
      ],
    );
  }
}
