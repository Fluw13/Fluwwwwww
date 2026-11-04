import 'package:flutter/material.dart';

import '../../core/theme/fluw_palette.dart';
import '../../models/product_model.dart';
import '../ai_unavailable_card.dart';
import '../tag_section.dart';
import '../zero_analysis_card.dart';
import 'data_source_footer.dart';
import 'nutrition_grid.dart';
import 'product_detail_layout.dart';
import 'product_header.dart';
import 'score_summary_card.dart';

/// The single layout used for every product: only the data changes.
/// Sections without data are hidden rather than shown empty.
class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final int? score = product.score;
    final ZeroAnalysisCard analysis = ZeroAnalysisCard(
      deepThink: product.deepThink,
      recommendation: product.recommendation,
    );

    return ProductDetailLayout(
      score: score != null ? ScoreSummaryCard(score: score) : AiUnavailableCard(aiError: product.aiError),
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
      sections: [
        if (product.hasAnalysis && analysis.hasContent) analysis,
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
        if (product.alternatives.isNotEmpty)
          TagSection(
            title: 'Lựa chọn lành mạnh hơn',
            tags: product.alternatives,
            tone: palette.scoreGood,
            icon: Icons.eco_outlined,
            note: 'Gợi ý chung do Zero tạo.',
          ),
      ],
      footer: const DataSourceFooter(),
    );
  }
}
