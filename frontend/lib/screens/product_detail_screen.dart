import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../models/product_model.dart';
import '../models/score_level.dart';
import '../services/api_service.dart';
import '../widgets/ai_unavailable_card.dart';
import '../widgets/async/async_content.dart';
import '../widgets/async/loading_status_banner.dart';
import '../widgets/circular_score_ring.dart';
import '../widgets/macro_bar.dart';
import '../widgets/tag_section.dart';
import '../widgets/zero_analysis_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.query, this.apiService});

  final String query;
  final ApiService? apiService;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ApiService _apiService;
  late final bool _ownsApiService;
  late Future<ProductModel> _productFuture;

  @override
  void initState() {
    super.initState();
    _ownsApiService = widget.apiService == null;
    _apiService = widget.apiService ?? ApiService();
    _productFuture = _apiService.fetchProduct(widget.query);
  }

  @override
  void dispose() {
    if (_ownsApiService) {
      _apiService.dispose();
    }
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
      body: AsyncContent<ProductModel>(
        future: _productFuture,
        loadingBuilder: (_) => _LoadingView(query: widget.query),
        errorBuilder: (_, error) => _ErrorView(error: error, onRetry: _retry),
        dataBuilder: (_, product) => _ProductContent(product: product),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.query});

  static final RegExp _barcodePattern = RegExp(r'^\d{8,14}$');

  final String query;

  @override
  Widget build(BuildContext context) {
    final String source = _barcodePattern.hasMatch(query) ? 'Mã $query' : 'Từ khóa “$query”';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!MediaQuery.disableAnimationsOf(context)) const LinearProgressIndicator(minHeight: 3),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            0,
          ),
          child: LoadingStatusBanner(
            title: 'Đang mở chi tiết sản phẩm',
            subtitle: '$source · Zero đang phân tích…',
            slowHint: 'Nếu máy chủ vừa khởi động, lần tra cứu đầu tiên có thể mất khoảng 1 phút.',
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Object cause = error;
    final String message = cause is ApiException
        ? cause.message
        : 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
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
    final FluwPalette palette = context.palette;
    final int? score = product.score;
    final ScoreLevel? level = product.level;

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
                      Icon(Icons.broken_image, size: 100, color: palette.textSecondary),
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
              style: TextStyle(color: palette.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (score != null && level != null) ...[
              CircularScoreRing(score: score),
              const SizedBox(height: 12),
              Text(
                level.label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ] else
              AiUnavailableCard(aiError: product.aiError),
            const SizedBox(height: 24),
            MacroBar(
              calories: product.calories,
              protein: product.protein,
              fat: product.fat,
              carbs: product.carbs,
            ),
            const SizedBox(height: 24),
            if (product.hasAnalysis) ...[
              ZeroAnalysisCard(
                deepThink: product.deepThink,
                recommendation: product.recommendation,
              ),
              const SizedBox(height: 24),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TagSection(
                title: 'Chất gây dị ứng theo nhãn',
                tags: product.declaredAllergens,
                tone: palette.scorePoor,
                note: 'Nguồn: OpenFoodFacts. Luôn kiểm tra nhãn bao bì trước khi dùng.',
              ),
            ),
            if (product.declaredAllergens.isNotEmpty) const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TagSection(
                title: 'Có thể chứa thêm (AI gợi ý)',
                tags: product.suggestedAllergens,
                tone: palette.scoreModerate,
                note: 'Zero suy ra từ danh sách thành phần, chưa được xác nhận trên nhãn.',
              ),
            ),
            if (product.suggestedAllergens.isNotEmpty) const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TagSection(
                title: 'Lựa chọn lành mạnh hơn',
                tags: product.alternatives,
                tone: palette.scoreGood,
                note: 'Gợi ý chung do Zero tạo.',
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Dữ liệu sản phẩm: OpenFoodFacts (giấy phép ODbL), do cộng đồng đóng góp và có thể chưa đầy đủ.\n'
              'Phân tích: Zero AI (Google Gemini).',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
