import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/search/search_results.dart';
import '../product/product_thumbnail.dart';
import '../skeleton/skeleton_box.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required SearchResultItem this.item,
    required VoidCallback this.onTap,
  });

  /// Same frame and spacing, text replaced by placeholders.
  const SearchResultTile.loading({super.key}) : item = null, onTap = null;

  static const double thumbnailSize = 56;
  static const double _titleSize = 15;
  static const double _titleHeight = 1.3;
  static const double _detailSize = 13;
  static const double _detailHeight = 1.35;
  static const String missingName = 'Chưa có tên sản phẩm';

  final SearchResultItem? item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final SearchResultItem? item = this.item;
    final TextStyle detailStyle = TextStyle(
      fontSize: _detailSize,
      height: _detailHeight,
      color: palette.textSecondary,
    );

    final Widget thumbnail = item == null
        ? const SkeletonBox(
            width: thumbnailSize,
            height: thumbnailSize,
            radius: AppRadius.md + 2,
          )
        : ProductThumbnail(imageUrl: item.imageUrl ?? '', size: thumbnailSize);

    final List<Widget> texts = item == null
        ? const [
            SkeletonBox.text(fontSize: _titleSize, lineHeight: _titleHeight),
            SizedBox(height: 2),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: SkeletonBox.text(
                fontSize: _detailSize,
                lineHeight: _detailHeight,
              ),
            ),
          ]
        : [
            Text(
              item.name ?? missingName,
              style: TextStyle(
                fontSize: _titleSize,
                height: _titleHeight,
                fontWeight: FontWeight.w600,
                color: item.name == null
                    ? palette.textSecondary
                    : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(_details(item), style: detailStyle),
          ];

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          thumbnail,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: texts,
            ),
          ),
          if (item != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: palette.textSecondary),
          ],
        ],
      ),
    );

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: item == null
          ? content
          : InkWell(
              onTap: onTap,
              child: Semantics(button: true, child: content),
            ),
    );
  }

  static String _details(SearchResultItem item) {
    return [
      item.brand,
      item.quantity,
      'Mã ${item.barcode}',
    ].whereType<String>().join(' · ');
  }
}
