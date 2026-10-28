import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../widgets/circular_score_ring.dart';
import '../widgets/macro_bar.dart';

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
                  Text('Zero đang phân tích dữ liệu...'),
                ],
              ),
            );
          }

          // XUẤT HIỆN LỖI: IN THẲNG RA MÀN HÌNH ĐỂ DEBUG
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'CHI TIẾT LỖI TỪ SERVER:\n\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
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
                CircularScoreRing(score: product.score),
                const SizedBox(height: 12),
                Text(
                  product.scoreRating,
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
                      const Row(
                        children: [
                          Icon(Icons.psychology, color: Color(0xFF141414)),
                          SizedBox(width: 8),
                          Text('Zero Deep Think', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                const SizedBox(height: 30),
                Text(
                  'Dữ liệu thực phẩm được cung cấp bởi OpenFoodFacts\n(Phát hành theo giấy phép ODbL)',
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
