import 'package:flutter/material.dart';

import '../../core/network/trusted_image_url.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';

/// Product photo. Decorative unless [onTap] is set: the product name next to
/// it carries the meaning, so a plain thumbnail is hidden from screen readers.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    required this.size,
    this.onTap,
    this.semanticsLabel,
  });

  final String imageUrl;
  final double size;

  /// Opens the photo, e.g. in full size.
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final Widget placeholder = Icon(
      Icons.image_outlined,
      size: size * 0.36,
      color: palette.textSecondary,
    );
    final int decodeSize = (size * MediaQuery.devicePixelRatioOf(context))
        .round();
    final BorderRadius radius = BorderRadius.circular(
      size >= 64 ? AppRadius.xl : AppRadius.md + 2,
    );

    final Widget image = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: radius,
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
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );

    final VoidCallback? onTap = this.onTap;
    if (onTap == null) return image;

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: radius, child: image),
      ),
    );
  }
}
