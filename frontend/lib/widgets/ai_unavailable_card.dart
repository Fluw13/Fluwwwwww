import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AiUnavailableCard extends StatelessWidget {
  const AiUnavailableCard({super.key, required this.aiError});

  final String? aiError;

  static String reasonFor(String? aiError) {
    switch (aiError) {
      case 'AI_NOT_CONFIGURED':
        return 'Tính năng phân tích AI hiện chưa được bật trên máy chủ.';
      case 'AI_INVALID_RESPONSE':
        return 'Zero trả về kết quả không hợp lệ nên đã được bỏ qua để tránh hiển thị thông tin sai.';
      default:
        return 'Trợ lý Zero tạm thời không phản hồi. Bạn có thể quay lại sau để xem đánh giá.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(Icons.auto_awesome_outlined, color: AppColors.ink),
              SizedBox(width: 8),
              Text(
                'Chưa có đánh giá AI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reasonFor(aiError),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Thông tin sản phẩm và dinh dưỡng bên dưới vẫn lấy từ OpenFoodFacts.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
