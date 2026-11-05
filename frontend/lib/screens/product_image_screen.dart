import 'package:flutter/material.dart';

import '../core/network/trusted_image_url.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../models/product/product_images.dart';

/// One product photo, zoomable. Only here is the original-size image
/// downloaded; the smaller one stays visible until it arrives.
class ProductImageScreen extends StatelessWidget {
  const ProductImageScreen({
    super.key,
    required this.image,
    required this.caption,
  });

  final ProductImageSet image;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? largest = trustedImageUrlOrNull(image.largest);
    final String? preview = trustedImageUrlOrNull(image.display ?? image.small);
    final Widget unavailable = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          'Không tải được ảnh. Vui lòng thử lại sau.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: palette.textSecondary),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Ảnh: $caption')),
      body: Column(
        children: [
          Expanded(
            child: largest == null
                ? unavailable
                : InteractiveViewer(
                    maxScale: 5,
                    child: Center(
                      child: Image.network(
                        largest,
                        fit: BoxFit.contain,
                        semanticLabel: 'Ảnh $caption của sản phẩm',
                        errorBuilder: (context, error, stackTrace) =>
                            unavailable,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              if (preview != null && preview != largest)
                                Image.network(
                                  preview,
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              const CircularProgressIndicator(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Ảnh: cộng tác viên Open Food Facts · CC BY-SA',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
