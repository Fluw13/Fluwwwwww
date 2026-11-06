import 'package:flutter/material.dart';

import '../../core/format/nutrient_format.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/product_summary.dart';
import 'product_thumbnail.dart';
import 'score_pill.dart';

/// The one card used by every product list (recent scans, history, later
/// search results). With large system text the score moves under the name
/// instead of squeezing it.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  static const double thumbnailSize = 56;
  static const String missingName = 'Chưa có tên sản phẩm';
  static const double _maxPillWidth = 140;
  static const double _stackedTextScale = 1.3;

  final ProductSummary product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final bool stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackedTextScale;
    final String detail = _detail;
    final Widget scorePill = ScorePill(
      score: product.score,
      level: product.level,
      label: product.levelLabel,
    );

    final Widget texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name ?? missingName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: product.name == null
                ? palette.textSecondary
                : palette.textPrimary,
          ),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: palette.textSecondary,
            ),
          ),
        ],
        if (stacked) ...[const SizedBox(height: AppSpacing.sm), scorePill],
      ],
    );

    return Semantics(
      button: true,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ProductThumbnail(
                  imageUrl: product.imageUrl ?? '',
                  size: thumbnailSize,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: texts),
                if (!stacked) ...[
                  const SizedBox(width: AppSpacing.sm),
                  // The level text comes from the backend; a long one wraps
                  // inside the pill instead of pushing the row off screen.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxPillWidth),
                    child: scorePill,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _detail {
    final double? calories = product.calories;
    return [
      ?product.brand,
      if (calories != null) '${NutrientFormat.kcal(calories)} kcal',
    ].where((part) => part.isNotEmpty).join(' · ');
  }
}
