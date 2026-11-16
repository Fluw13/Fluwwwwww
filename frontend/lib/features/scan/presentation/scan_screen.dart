import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/scan/domain/gtin.dart';
import 'package:fluw/features/scan/presentation/barcode_camera.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({required this.onBarcode, super.key});

  /// Opens the product with this barcode; completes when the user comes back, so scanning resumes only then.
  final Future<void> Function(String code) onBarcode;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final TextEditingController _manualCode = TextEditingController();
  late final AppLifecycleListener _lifecycle;
  bool _isForeground = true;
  bool _isOpening = false;
  String? _manualError;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) => setState(() => _isForeground = state == AppLifecycleState.resumed),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _manualCode.dispose();
    super.dispose();
  }

  Future<void> _open(String code) async {
    if (_isOpening) {
      return;
    }
    setState(() => _isOpening = true);
    HapticFeedback.mediumImpact().ignore();
    try {
      await widget.onBarcode(code);
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  /// A misread code fails the check digit; the camera simply keeps looking.
  void _onDetected(String code) {
    if (isValidGtin(code)) {
      _open(code);
    }
  }

  void _submitManualCode() {
    final code = _manualCode.text.trim();
    if (!isValidGtin(code)) {
      setState(() => _manualError = 'Mã vạch có 8, 12, 13 hoặc 14 chữ số. Hãy kiểm tra lại các số đã nhập.');
      return;
    }
    setState(() => _manualError = null);
    FocusManager.instance.primaryFocus?.unfocus();
    _open(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    // TickerMode is off while another tab or a page on top is shown (go_router and Navigator both set it).
    final cameraActive = TickerMode.valuesOf(context).enabled && _isForeground && !_isOpening;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text('Quét mã vạch', style: theme.textTheme.titleLarge),
        Text('Hướng camera vào mã vạch trên bao bì. Fluw tìm sản phẩm trên Open Food Facts.', style: muted),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ref.watch(barcodeCameraProvider).build(active: cameraActive, onDetected: _onDetected),
                IgnorePointer(
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      heightFactor: 0.4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.primaryContainer, width: 3),
                          borderRadius: BorderRadius.circular(AppRadius.control),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isOpening) ...[
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(),
          Text('Đang mở sản phẩm...', style: muted),
        ],
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Nhập mã bằng tay',
          children: [
            TextField(
              controller: _manualCode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 14,
              decoration: InputDecoration(labelText: 'Mã vạch (8–14 chữ số)', errorText: _manualError),
              onSubmitted: (_) => _submitManualCode(),
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _isOpening ? null : _submitManualCode,
              icon: const Icon(Icons.search),
              label: const Text('Tra mã'),
            ),
          ],
        ),
      ],
    );
  }
}
