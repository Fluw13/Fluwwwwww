import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/product_summary.dart';
import '../common/section_title.dart';
import '../product/product_card.dart';

class RecentScansSection extends StatelessWidget {
  const RecentScansSection({super.key, required this.scans, required this.onOpen, required this.onSeeAll});

  static const int maxShown = 3;

  final List<ProductSummary> scans;
  final ValueChanged<ProductSummary> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionTitle('Vừa quét')),
            TextButton(onPressed: onSeeAll, child: const Text('Xem tất cả')),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final ProductSummary product in scans.take(maxShown))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ProductCard(product: product, onTap: () => onOpen(product)),
          ),
      ],
    );
  }
}
