import 'package:flutter/material.dart';

import '../../core/theme/fluw_palette.dart';
import '../../models/product/product.dart';
import '../../models/product/product_details.dart';
import '../../models/product/product_images.dart';
import '../../models/product/product_nutrition.dart';
import '../../models/product/product_tags.dart';
import '../../screens/product_image_screen.dart';
import '../../screens/score_explanation_screen.dart';
import '../common/labeled_value.dart';
import '../tag_section.dart';
import 'additives_section.dart';
import 'data_source_footer.dart';
import 'ingredients_section.dart';
import 'nutrition_grid.dart';
import 'product_detail_layout.dart';
import 'product_header.dart';
import 'product_images_section.dart';
import 'product_info_section.dart';
import 'score_summary_card.dart';

/// The single layout used for every product: only the data changes. Missing
/// data is written out as "Chưa có dữ liệu" rather than guessed or hidden.
class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key, required this.details});

  final ProductDetails details;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final Product product = details.product;
    final NutrientValues? prepared = product.nutrition.preparedPer100;

    void openImage(ProductImageSet image, String caption) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductImageScreen(image: image, caption: caption),
        ),
      );
    }

    final ProductImagesSection photos = ProductImagesSection(
      images: product.images,
      onOpen: openImage,
    );

    return ProductDetailLayout(
      score: ScoreSummaryCard(
        score: details.score,
        onExplain: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScoreExplanationScreen(details: details),
          ),
        ),
      ),
      header: ProductHeader(
        product: product,
        onOpenImage: (image) => openImage(image, 'Mặt trước'),
      ),
      nutrition: NutritionGrid(
        values: product.nutrition.per100,
        basis: product.nutrition.basis,
      ),
      sections: [
        if (prepared != null)
          NutritionGrid(
            values: prepared,
            basis: product.nutrition.basis,
            prepared: true,
          ),
        IngredientsSection(text: product.ingredientsText),
        TagSection(
          title: 'Chất gây dị ứng theo nhãn',
          tags: _labels(product.allergens),
          tone: palette.scorePoor,
          icon: Icons.warning_amber_rounded,
          emptyText: LabeledValue.missing,
        ),
        TagSection(
          title: 'Có thể chứa',
          tags: _labels(product.traces),
          tone: palette.scoreModerate,
          emptyText: LabeledValue.missing,
          note: 'Nguồn: Open Food Facts. Luôn kiểm tra nhãn bao bì trước khi dùng.',
        ),
        AdditivesSection(
          additives: product.additives,
          score: details.score.additives,
        ),
        ProductInfoSection(product: product),
        if (photos.hasImages) photos,
      ],
      footer: DataSourceFooter(source: product.source),
    );
  }

  static List<String> _labels(List<ProductTag> tags) => [
    for (final ProductTag tag in tags) tag.label,
  ];
}
