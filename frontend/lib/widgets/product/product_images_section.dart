import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/product/product_images.dart';
import '../common/section_title.dart';
import 'product_thumbnail.dart';

/// The product's photos on Open Food Facts (front, ingredients, nutrition
/// facts), small size only. Tapping one opens it in full size. Hidden when the
/// product has no photo.
class ProductImagesSection extends StatelessWidget {
  const ProductImagesSection({
    super.key,
    required this.images,
    required this.onOpen,
  });

  static const double thumbnailSize = 88;

  final ProductImages images;
  final void Function(ProductImageSet image, String caption) onOpen;

  List<(String, ProductImageSet)> get _available => [
    if (images.front case final ProductImageSet front) ('Mặt trước', front),
    if (images.ingredients case final ProductImageSet ingredients)
      ('Thành phần', ingredients),
    if (images.nutrition case final ProductImageSet nutrition)
      ('Bảng dinh dưỡng', nutrition),
  ];

  bool get hasImages => _available.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final List<(String, ProductImageSet)> available = _available;
    if (available.isEmpty) return const SizedBox.shrink();
    final FluwPalette palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Ảnh sản phẩm'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final (String caption, ProductImageSet image) in available)
              SizedBox(
                width: thumbnailSize,
                child: Column(
                  children: [
                    ProductThumbnail(
                      imageUrl: image.preview ?? '',
                      size: thumbnailSize,
                      onTap: () => onOpen(image, caption),
                      semanticsLabel: 'Phóng to ảnh $caption',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ExcludeSemantics(
                      child: Text(
                        caption,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ảnh: cộng tác viên Open Food Facts · CC BY-SA',
          style: TextStyle(fontSize: 12, color: palette.textSecondary),
        ),
      ],
    );
  }
}
