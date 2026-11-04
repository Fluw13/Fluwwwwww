import 'package:flutter/material.dart';

import '../../core/network/trusted_image_url.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';

/// Decorative product photo; the product name next to it carries the meaning,
/// so the image is hidden from screen readers.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final Widget placeholder = Icon(Icons.image_outlined, size: size * 0.36, color: palette.textSecondary);
    final int decodeSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(size >= 64 ? AppRadius.xl : AppRadius.md + 2),
        border: Border.all(color: palette.border),
      ),
      alignment: Alignment.center,
      child: !isTrustedImageUrl(imageUrl)
          ? placeholder
          : Image.network(
              imageUrl,
              width: size,
              height: size,
              cacheWidth: decodeSize,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => placeholder,
              loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
            ),
    );
  }
}
