import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../skeleton/skeleton_box.dart';
import 'product_detail_metrics.dart';
import 'product_thumbnail.dart';

class ProductHeader extends StatelessWidget {
  const ProductHeader({
    super.key,
    required String this.name,
    required String this.brand,
    required String this.barcode,
    required String this.imageUrl,
  });

  const ProductHeader.loading({super.key}) : name = null, brand = null, barcode = null, imageUrl = null;

  static const double _nameSize = 20;
  static const double _nameHeight = 1.25;
  static const double _subtitleSize = 14;
  static const double _subtitleHeight = 1.3;

  final String? name;
  final String? brand;
  final String? barcode;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? name = this.name;
    final String? imageUrl = this.imageUrl;

    final Widget thumbnail = imageUrl == null
        ? const SkeletonBox(
            width: ProductDetailMetrics.thumbnailSize,
            height: ProductDetailMetrics.thumbnailSize,
            radius: AppRadius.xl,
          )
        : ProductThumbnail(imageUrl: imageUrl, size: ProductDetailMetrics.thumbnailSize);

    final List<Widget> texts = name == null
        ? const [
            SkeletonBox.text(fontSize: _nameSize, lineHeight: _nameHeight),
            SizedBox(height: AppSpacing.xs),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: SkeletonBox.text(fontSize: _subtitleSize, lineHeight: _subtitleHeight),
            ),
          ]
        : [
            Semantics(
              header: true,
              child: Text(
                name,
                style: const TextStyle(fontSize: _nameSize, height: _nameHeight, fontWeight: FontWeight.w700),
              ),
            ),
            if (_subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _subtitle,
                style: TextStyle(fontSize: _subtitleSize, height: _subtitleHeight, color: palette.textSecondary),
              ),
            ],
          ];

    return Row(
      children: [
        thumbnail,
        const SizedBox(width: AppSpacing.md + 2),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: texts),
        ),
      ],
    );
  }

  String get _subtitle => [brand, barcode].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
}
