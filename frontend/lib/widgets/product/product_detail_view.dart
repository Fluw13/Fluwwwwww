import 'package:flutter/material.dart';

import '../../core/format/nutrient_format.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/fns_result.dart';
import '../../models/product_model.dart';
import '../ai_unavailable_card.dart';
import '../tag_section.dart';
import '../zero_analysis_card.dart';
import 'data_source_footer.dart';
import 'fns_breakdown_card.dart';
import 'fns_not_scored_card.dart';
import 'nutrition_grid.dart';
import 'product_detail_layout.dart';
import 'product_header.dart';
import 'score_summary_card.dart';

/// The single layout used for every product: only the data changes.
/// Sections without data are hidden rather than shown empty.
class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key, required this.product});

  final ProductModel product;

  static String? _grams(double? value) => value == null ? null : '${NutrientFormat.grams(value)} g';

  Map<String, String> _componentValues() {
    final double? calories = product.calories;
    final double? sodiumMg = product.sodiumMg;
    return {
      'energy': ?(calories == null ? null : '${NutrientFormat.kcal(calories)} kcal'),
      'saturated_fat': ?_grams(product.saturatedFat),
      'total_sugars': ?_grams(product.sugars),
      'sodium': ?(sodiumMg == null ? null : '${NutrientFormat.kcal(sodiumMg)} mg'),
      'protein': ?_grams(product.protein),
      'fiber': ?_grams(product.fiber),
    };
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final FnsResult fns = product.fns;
    final ZeroAnalysisCard analysis = ZeroAnalysisCard(
      deepThink: product.deepThink,
      recommendation: product.recommendation,
    );

    return ProductDetailLayout(
      score: fns.isScored ? ScoreSummaryCard(fns: fns) : FnsNotScoredCard(fns: fns),
      header: ProductHeader(
        name: product.name,
        brand: product.brand,
        barcode: product.barcode,
        imageUrl: product.imageUrl,
      ),
      nutrition: NutritionGrid(
        calories: product.calories,
        protein: product.protein,
        fat: product.fat,
        carbs: product.carbs,
      ),
      // Zero comes first so it sits where ProductDetailSkeleton shows its placeholder.
      sections: [
        if (!product.hasAnalysis) AiUnavailableCard(aiError: product.aiError) else if (analysis.hasContent) analysis,
        if (fns.isScored) FnsBreakdownCard(fns: fns, values: _componentValues()),
        if (product.declaredAllergens.isNotEmpty)
          TagSection(
            title: 'Chất gây dị ứng theo nhãn',
            tags: product.declaredAllergens,
            tone: palette.scorePoor,
            icon: Icons.warning_amber_rounded,
            note: 'Nguồn: Open Food Facts. Luôn kiểm tra nhãn bao bì trước khi dùng.',
          ),
        if (product.suggestedAllergens.isNotEmpty)
          TagSection(
            title: 'Có thể chứa thêm (AI gợi ý)',
            tags: product.suggestedAllergens,
            tone: palette.scoreModerate,
            note: 'Zero suy ra từ danh sách thành phần, chưa được xác nhận trên nhãn.',
          ),
      ],
      footer: const DataSourceFooter(),
    );
  }
}
