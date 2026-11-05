import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/product/product.dart';
import '../common/labeled_value.dart';
import '../common/section_title.dart';

/// Brand, quantity and manufacturer as declared on Open Food Facts.
class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Thông tin sản phẩm'),
        const SizedBox(height: AppSpacing.xs),
        LabeledValue(label: 'Tên chung', value: product.genericName),
        LabeledValue(label: 'Thương hiệu', value: product.brand),
        LabeledValue(label: 'Khối lượng / thể tích', value: product.quantity),
        LabeledValue(
          label: 'Chủ sở hữu thương hiệu',
          value: product.brandOwner,
        ),
        LabeledValue(label: 'Nơi sản xuất', value: product.manufacturingPlaces),
        LabeledValue(label: 'Mã vạch', value: product.barcode),
      ],
    );
  }
}
