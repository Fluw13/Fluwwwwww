import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/product/product.dart';
import '../../models/product/product_images.dart';
import '../skeleton/skeleton_box.dart';
import 'product_detail_metrics.dart';
import 'product_thumbnail.dart';

class ProductHeader extends StatelessWidget {
  const ProductHeader({
    super.key,
    required Product this.product,
    this.onOpenImage,
  });

  const ProductHeader.loading({super.key}) : product = null, onOpenImage = null;

  static const String missingName = 'Chưa có tên sản phẩm';
  static const double _nameSize = 20;
  static const double _nameHeight = 1.25;
  static const double _subtitleSize = 14;
  static const double _subtitleHeight = 1.3;

  final Product? product;

  /// Opens the front photo in full size.
  final ValueChanged<ProductImageSet>? onOpenImage;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final Product? product = this.product;

    if (product == null) {
      return const Row(
        children: [
          SkeletonBox(
            width: ProductDetailMetrics.thumbnailSize,
            height: ProductDetailMetrics.thumbnailSize,
            radius: AppRadius.xl,
          ),
          SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox.text(fontSize: _nameSize, lineHeight: _nameHeight),
                SizedBox(height: AppSpacing.xs),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: SkeletonBox.text(
                    fontSize: _subtitleSize,
                    lineHeight: _subtitleHeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final ProductImageSet? front = product.images.front;
    final ValueChanged<ProductImageSet>? onOpenImage = this.onOpenImage;
    final String subtitle = [
      product.brand,
      product.quantity,
      product.barcode,
    ].whereType<String>().join(' · ');

    return Row(
      children: [
        ProductThumbnail(
          imageUrl: _thumbnailUrl(context, front) ?? '',
          size: ProductDetailMetrics.thumbnailSize,
          onTap: front == null || onOpenImage == null
              ? null
              : () => onOpenImage(front),
          semanticsLabel: 'Phóng to ảnh sản phẩm',
        ),
        const SizedBox(width: AppSpacing.md + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  product.name ?? missingName,
                  style: TextStyle(
                    fontSize: _nameSize,
                    height: _nameHeight,
                    fontWeight: FontWeight.w700,
                    color: product.name == null
                        ? palette.textSecondary
                        : palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: _subtitleSize,
                  height: _subtitleHeight,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The 200 px image is enough for the 72 px box up to about 2.75x density.
  static String? _thumbnailUrl(BuildContext context, ProductImageSet? images) {
    if (images == null) return null;
    final double pixels =
        ProductDetailMetrics.thumbnailSize *
        MediaQuery.devicePixelRatioOf(context);
    return pixels > 200 ? (images.display ?? images.small) : images.preview;
  }
}
