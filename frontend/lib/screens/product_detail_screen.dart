import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../widgets/circular_score_ring.dart';
import '../widgets/macro_bar.dart';

const String _defaultAiDisclaimer =
    'Phân tích do AI tạo ra, chỉ mang tính tham khảo, không thay thế tư vấn của bác sĩ hoặc chuyên gia dinh dưỡng. Luôn đọc nhãn sản phẩm, đặc biệt nếu bạn bị dị ứng.';
const String _genericErrorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
const String _noAiMessage = 'Chưa có phân tích AI cho sản phẩm này. Bạn vẫn xem được thông tin dinh dưỡng bên dưới.';
const String _dataAttribution =
    'Dữ liệu: Open Food Facts (openfoodfacts.org) — giấy phép ODbL. Ảnh sản phẩm: Open Food Facts contributors — CC BY-SA.';

class ProductDetailScreen extends StatelessWidget {
  final String barcode;

  const ProductDetailScreen({super.key, required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF141414),
      ),
      body: FutureBuilder<ProductModel>(
        future: ApiService.fetchProductByBarcode(barcode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00E676)),
                  SizedBox(height: 16),
                  Text(
                    'Zero đang phân tích dữ liệu...\nLần đầu mở app có thể mất tới 1 phút.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            final Object? error = snapshot.error;
            final String userMessage = error is ApiException ? error.userMessage : _genericErrorMessage;
            final String? debugDetail = error is ApiException ? error.debugDetail : error?.toString();

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      userMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF141414)),
                    ),
                    if (kDebugMode && debugDetail != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Debug: $debugDetail',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (product.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      product.imageUrl,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
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
                if (product.hasAiAnalysis) ...[
                  CircularScoreRing(score: product.score),
                  const SizedBox(height: 12),
                  Text(
                    product.scoreRating,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ] else
                  Text(
                    _noAiMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                const SizedBox(height: 24),
                MacroBar(
                  calories: product.calories,
                  protein: product.protein,
                  fat: product.fat,
                  carbs: product.carbs,
                ),
                if (product.hasAiAnalysis) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology, color: Color(0xFF141414)),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Zero Deep Think',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                'Do AI tạo',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(product.deepThink, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
                        const Divider(height: 24),
                        const Text('Lời khuyên dinh dưỡng:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(product.recommendation, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.disclaimer ?? _defaultAiDisclaimer,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 30),
                Text(
                  _dataAttribution,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
