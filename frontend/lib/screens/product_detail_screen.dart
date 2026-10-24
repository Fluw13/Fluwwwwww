import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../widgets/macro_bar.dart';
import '../widgets/circular_score_ring.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductDetailResponse detail;

  const ProductDetailScreen({super.key, required this.detail});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isThoughtExpanded = true;

  @override
  Widget build(BuildContext context) {
    final product = widget.detail.product;
    final ai = widget.detail.aiAnalysis;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Log food', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 80,
                                    width: 80,
                                    color: const Color(0xFFF1F3F5),
                                    child: const Icon(Icons.fastfood, size: 36, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  height: 80,
                                  width: 80,
                                  color: const Color(0xFFF1F3F5),
                                  child: const Icon(Icons.fastfood, size: 36, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle, color: Color(0xFF1C7ED6), size: 18),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.brand} • ${product.quantity}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF868E96)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mã: ${product.barcode}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFADB5BD)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ô TRÒN ĐIỂM SỐ XANH - VÀNG - ĐỎ TO Ở CHÍNH GIỮA MÀN HÌNH
                  CircularScoreRing(score: ai.healthScore),
                  const SizedBox(height: 20),

                  // Thanh Macro 4 chỉ số (Kcal, Đạm, Béo, Carb)
                  MacroBar(
                    calories: '${(ai.healthScore * 3.5).toInt()}',
                    protein: '${(ai.healthScore * 0.12).toStringAsFixed(1)}g',
                    fat: '${(ai.healthScore * 0.15).toStringAsFixed(1)}g',
                    carbs: '${(ai.healthScore * 0.6).toStringAsFixed(1)}g',
                  ),
                  const SizedBox(height: 16),

                  // Hộp AI Zero Deep Think
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isThoughtExpanded = !_isThoughtExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFF141414),
                                child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Zero đã phân tích trong 1.5s',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Icon(
                                _isThoughtExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: const Color(0xFF868E96),
                              )
                            ],
                          ),
                        ),
                        if (_isThoughtExpanded) ...[
                          const SizedBox(height: 12),
                          _buildThoughtStep('Đã rà soát danh sách thành phần và chất béo'),
                          _buildThoughtStep('Đối chiếu khuyến nghị dinh dưỡng quốc tế'),
                          _buildThoughtStep('Tổng hợp lời khuyên và gợi ý thay thế'),
                          const Divider(height: 24),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          ai.ratingLabel,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ai.summary,
                          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF495057)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (ai.allergensWarning.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFE3E3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFFA5252), size: 18),
                              SizedBox(width: 6),
                              Text('Cảnh báo thành phần / Dị ứng', style: TextStyle(color: Color(0xFFE03131), fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: ai.allergensWarning.map((w) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('• $w', style: const TextStyle(color: Color(0xFFC92A2A), fontSize: 12, fontWeight: FontWeight.w600)),
                            )).toList(),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Color(0xFFFAB005), size: 18),
                            SizedBox(width: 6),
                            Text('Lời khuyên từ Zero', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(ai.dietaryAdvice, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF495057))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (ai.alternatives.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text('Gợi ý lành mạnh hơn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    ...ai.alternatives.map((alt) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.recommend, color: Color(0xFF40C057)),
                            title: Text(alt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right, size: 16),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu vào nhật ký ăn uống thành công!')),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141414),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text('Add to log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildThoughtStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check, size: 14, color: Color(0xFF40C057)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF868E96)))),
        ],
      ),
    );
  }
}
