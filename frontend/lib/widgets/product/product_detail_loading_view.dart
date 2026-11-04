import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../async/loading_status_banner.dart';
import 'product_detail_skeleton.dart';

/// Shown while a product loads. The skeleton starts exactly where the content
/// will start; the progress bar and the banner float on top of it, so nothing
/// moves when the data arrives.
class ProductDetailLoadingView extends StatelessWidget {
  const ProductDetailLoadingView({super.key, required this.query});

  static final RegExp _barcodePattern = RegExp(r'^\d{8,14}$');

  final String query;

  @override
  Widget build(BuildContext context) {
    final String source = _barcodePattern.hasMatch(query) ? 'Mã $query' : 'Từ khóa “$query”';

    return Stack(
      children: [
        const Positioned.fill(child: ProductDetailSkeleton()),
        if (!MediaQuery.disableAnimationsOf(context))
          const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 3)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.lg),
            child: LoadingStatusBanner(
              title: 'Đang mở chi tiết sản phẩm',
              subtitle: '$source · Zero đang phân tích…',
              slowHint: 'Nếu máy chủ vừa khởi động, lần tra cứu đầu tiên có thể mất khoảng 1 phút.',
            ),
          ),
        ),
      ],
    );
  }
}
