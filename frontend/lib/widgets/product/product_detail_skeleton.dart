import 'package:flutter/material.dart';

import '../skeleton/shimmer_scope.dart';
import '../zero_analysis_card.dart';
import 'nutrition_grid.dart';
import 'product_detail_layout.dart';
import 'product_header.dart';
import 'score_summary_card.dart';

/// The product page while it loads: the same layout and the same section
/// widgets in their loading form, so blocks sit exactly where content appears.
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerScope(
      child: ProductDetailLayout(
        physics: NeverScrollableScrollPhysics(),
        score: ScoreSummaryCard.loading(),
        header: ProductHeader.loading(),
        nutrition: NutritionGrid.loading(),
        sections: [ZeroAnalysisCard.loading()],
      ),
    );
  }
}
