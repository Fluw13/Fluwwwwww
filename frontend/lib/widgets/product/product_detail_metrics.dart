import 'package:flutter/widgets.dart';

import '../../core/theme/app_spacing.dart';

/// Sizes and paddings shared by the real sections and their loading
/// placeholders, so a skeleton has exactly the shape of the content.
class ProductDetailMetrics {
  const ProductDetailMetrics._();

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    AppSpacing.screenPadding,
    AppSpacing.md,
    AppSpacing.screenPadding,
    AppSpacing.xxl,
  );
  static const double sectionGap = 16;

  static const EdgeInsets scoreCardPadding = EdgeInsets.fromLTRB(AppSpacing.xl, 28, AppSpacing.xl, AppSpacing.xxl);
  static const double scoreRingSize = 160;

  static const double thumbnailSize = 72;

  static const EdgeInsets nutrientTilePadding = EdgeInsets.all(AppSpacing.lg);

  /// A minimum, not a fixed height: tiles grow with large system text sizes.
  static const double nutrientTileMinHeight = 124;

  static const EdgeInsets analysisCardPadding = EdgeInsets.all(18);
}
