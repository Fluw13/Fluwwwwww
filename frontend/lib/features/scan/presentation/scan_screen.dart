import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/search/search_request.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/scan/domain/gtin.dart';
import 'package:fluw/features/scan/presentation/barcode_camera.dart';
import 'package:fluw/features/scan/presentation/photo_recognition_panel.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({required this.onBarcode, required this.onOpenSearch, super.key});

  /// Opens the product with this barcode; completes when the user comes back, so scanning resumes only then.
  final Future<void> Function(String code) onBarcode;

  /// Opens the search tab, which runs the search asked for through `searchRequestProvider`.
  final VoidCallback onOpenSearch;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final TextEditingController _manualCode = TextEditingController();
  bool _isOpening = false;
  bool _photoMode = false;
  String? _manualError;

  @override
  void dispose() {
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
      setState(
        () => _manualError = hasGtinLength(code)
            ? 'Có một chữ số bị sai (số cuối là số kiểm tra không khớp). Hãy so lại với mã trên bao bì.'
            : 'Mã vạch có 8, 12, 13 hoặc 14 chữ số. Hãy kiểm tra lại các số đã nhập.',
      );
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
    // Opening a product covers the tab, which turns TickerMode off at once; leaving the app is handled by the camera
    // view itself.
    final cameraActive = !_photoMode && TickerMode.valuesOf(context).enabled;
    final modes = SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, icon: Icon(Icons.qr_code_scanner), label: Text('Mã vạch')),
        ButtonSegment(value: true, icon: Icon(Icons.photo_camera_outlined), label: Text('Ảnh món ăn')),
      ],
      selected: {_photoMode},
      onSelectionChanged: (selection) => setState(() => _photoMode = selection.single),
    );
    // Both modes stay built, so a recognition result or a typed code survives switching back and forth.
    return IndexedStack(
      index: _photoMode ? 1 : 0,
      children: [
        _barcodeMode(theme, muted, modes, cameraActive: cameraActive),
        ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            modes,
            const SizedBox(height: AppSpacing.md),
            PhotoRecognitionPanel(
              onSearchFood: (food) {
                ref.read(searchRequestProvider.notifier).request(food.searchQuery, englishQuery: food.englishQuery);
                widget.onOpenSearch();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _barcodeMode(ThemeData theme, TextStyle? muted, Widget modes, {required bool cameraActive}) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        modes,
        const SizedBox(height: AppSpacing.md),
        Text('Quét mã vạch', style: theme.textTheme.titleLarge),
        Text('Hướng camera vào mã vạch trên bao bì. Fluw tìm sản phẩm trên Open Food Facts.', style: muted),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          container: true,
          label: cameraActive ? 'Camera quét mã vạch đang bật' : 'Camera quét mã vạch đang tắt',
          child: ClipRRect(
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
              onChanged: (_) {
                if (_manualError != null) {
                  setState(() => _manualError = null);
                }
              },
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
