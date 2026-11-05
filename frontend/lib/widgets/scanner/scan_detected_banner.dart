import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

/// Confirms which code was read and that the product page is opening.
class ScanDetectedBanner extends StatelessWidget {
  const ScanDetectedBanner({super.key, required this.barcode});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg + 2),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: palette.scoreGood.container, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 16, color: palette.scoreGood.text),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã nhận mã $barcode',
                        semanticsLabel: 'Đã nhận mã ${barcode.split('').join(' ')}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textPrimary),
                      ),
                      Text(
                        'Đang mở Chi tiết sản phẩm…',
                        style: TextStyle(fontSize: 13, color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!MediaQuery.disableAnimationsOf(context)) ...[
              const SizedBox(height: AppSpacing.sm + 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: const LinearProgressIndicator(minHeight: 4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
