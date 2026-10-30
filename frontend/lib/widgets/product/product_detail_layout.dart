import 'package:flutter/material.dart';

import 'product_detail_metrics.dart';

/// Order, spacing and padding of the product page. Used by both the loaded
/// view and its skeleton, so the two cannot drift apart.
class ProductDetailLayout extends StatelessWidget {
  const ProductDetailLayout({
    super.key,
    required this.score,
    required this.header,
    required this.nutrition,
    this.sections = const [],
    this.footer,
    this.physics,
  });

  final Widget score;
  final Widget header;
  final Widget nutrition;
  final List<Widget> sections;
  final Widget? footer;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    const SizedBox gap = SizedBox(height: ProductDetailMetrics.sectionGap);
    final Widget? footer = this.footer;

    return SingleChildScrollView(
      physics: physics,
      padding: ProductDetailMetrics.pagePadding,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            score,
            gap,
            header,
            gap,
            nutrition,
            for (final Widget section in sections) ...[gap, section],
            if (footer != null) ...[const SizedBox(height: ProductDetailMetrics.sectionGap * 1.5), footer],
          ],
        ),
      ),
    );
  }
}
