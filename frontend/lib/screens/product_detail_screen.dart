import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../widgets/circular_score_ring.dart';
import '../widgets/macro_bar.dart';
import '../widgets/tag_section.dart';
import '../widgets/zero_analysis_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.query});

  final String query;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<ProductModel> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = _apiService.fetchProduct(widget.query);
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _productFuture = _apiService.fetchProduct(widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      body: FutureBuilder<ProductModel>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingView();
          }

          final ProductModel? product = snapshot.data;
          if (product == null) {
            return _ErrorView(error: snapshot.error, onRetry: _retry);
          }

          return _ProductContent(product: product);
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 16),
          Text('Zero đang phân tích dữ liệu...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Object? cause = error;
    final String message = cause is ApiException
        ? cause.message
        : 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _ProductContent extends StatelessWidget {
  const _ProductContent({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (product.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  product.imageUrl,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              product.brand,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            CircularScoreRing(score: product.score),
            const SizedBox(height: 12),
            Text(
              product.level.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            MacroBar(
              calories: product.calories,
              protein: product.protein,
              fat: product.fat,
              carbs: product.carbs,
            ),
            const SizedBox(height: 24),
            ZeroAnalysisCard(
              deepThink: product.deepThink,
              recommendation: product.recommendation,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TagSection(
                title: 'Chất gây dị ứng theo nhãn',
                tags: product.declaredAllergens,
                tagColor: AppColors.danger,
                note: 'Nguồn: OpenFoodFacts. Luôn kiểm tra nhãn bao bì trước khi dùng.',
              ),
            ),
            if (product.declaredAllergens.isNotEmpty) const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TagSection(
                title: 'Có thể chứa thêm (AI gợi ý)',
                tags: product.suggestedAllergens,
                tagColor: AppColors.warning,
                note: 'Zero suy ra từ danh sách thành phần, chưa được xác nhận trên nhãn.',
              ),
            ),
            if (product.suggestedAllergens.isNotEmpty) const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TagSection(
                title: 'Lựa chọn lành mạnh hơn',
                tags: product.alternatives,
                tagColor: AppColors.accent,
                note: 'Gợi ý chung do Zero tạo.',
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Dữ liệu sản phẩm: OpenFoodFacts (giấy phép ODbL), do cộng đồng đóng góp và có thể chưa đầy đủ.\n'
              'Phân tích: Zero AI (Google Gemini).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
