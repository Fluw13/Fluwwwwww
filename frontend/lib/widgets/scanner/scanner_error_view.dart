import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_spacing.dart';

/// Why the camera could not start, with a retry (for example after the user
/// has granted the permission in Settings). Scrolls with large text.
class ScannerErrorView extends StatelessWidget {
  const ScannerErrorView({super.key, required this.errorCode, required this.onRetry});

  /// A device without a usable camera will not succeed on a retry.
  bool get _canRetry => errorCode != MobileScannerErrorCode.unsupported;

  final MobileScannerErrorCode errorCode;
  final VoidCallback onRetry;

  static ({String title, String message}) textFor(MobileScannerErrorCode code) {
    return switch (code) {
      MobileScannerErrorCode.permissionDenied => (
        title: 'Fluw chưa được phép dùng camera',
        message:
            'Bật quyền Camera cho Fluw trong Cài đặt của điện thoại để quét mã vạch, '
            'hoặc nhập mã thủ công bên dưới.',
      ),
      MobileScannerErrorCode.unsupported => (
        title: 'Thiết bị không hỗ trợ quét',
        message: 'Camera của thiết bị này không dùng được để quét mã vạch. Bạn có thể nhập mã thủ công bên dưới.',
      ),
      _ => (
        title: 'Không mở được camera',
        message: 'Hãy đóng màn hình này rồi thử lại, hoặc nhập mã thủ công bên dưới.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ({String title, String message}) text = textFor(errorCode);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (constraints.maxHeight - AppSpacing.lg * 2).clamp(0, double.infinity)),
          child: Center(
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography_outlined, size: 48, color: Colors.white),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    text.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    text.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFD3D9D5), fontSize: 14, height: 1.5),
                  ),
                  if (_canRetry) ...[
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton(
                      onPressed: onRetry,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x80FFFFFF)),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
