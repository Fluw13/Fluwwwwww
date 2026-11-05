import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format/date_format.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/product/product_source.dart';

/// Source and licences of the product data, its last update on Open Food
/// Facts, and a copyable link so users can complete the product there.
class DataSourceFooter extends StatelessWidget {
  const DataSourceFooter({super.key, required this.source});

  static const String copyLabel = 'Sao chép link sản phẩm';
  static const String copiedMessage =
      'Đã sao chép link sản phẩm trên Open Food Facts.';

  final ProductSource source;

  String get attribution {
    final String provider = source.provider ?? 'Open Food Facts';
    final String license = source.license ?? 'ODbL';
    final String imagesLicense = source.imagesLicense ?? 'CC BY-SA';
    return 'Dữ liệu: $provider · $license · ảnh $imagesLicense';
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(copiedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final TextStyle style = TextStyle(
      fontSize: 12,
      height: 1.55,
      color: palette.textSecondary,
    );
    final DateTime? lastModified = source.lastModified;
    final String? url = source.url;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Column(
        children: [
          Text(
            attribution,
            textAlign: TextAlign.center,
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            'Cập nhật trên Open Food Facts: '
            '${lastModified == null ? 'Chưa có dữ liệu' : formatVietnameseDate(lastModified)}',
            textAlign: TextAlign.center,
            style: style,
          ),
          Text(
            'Dữ liệu do cộng đồng đóng góp và có thể chưa đầy đủ. '
            'Giải thích bằng AI (Zero, Google Gemini) chỉ có khi bạn bấm "Hỏi Zero".',
            textAlign: TextAlign.center,
            style: style,
          ),
          if (url != null) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () => _copyLink(context, url),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text(copyLabel),
            ),
          ],
        ],
      ),
    );
  }
}
