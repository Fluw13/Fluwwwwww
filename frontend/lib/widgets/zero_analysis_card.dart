import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class ZeroAnalysisCard extends StatelessWidget {
  const ZeroAnalysisCard({
    super.key,
    required this.deepThink,
    required this.recommendation,
  });

  final String deepThink;
  final String recommendation;

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
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.ink),
              const SizedBox(width: 8),
              const Text(
                'Zero Deep Think',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Text(
                'Do AI tạo',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (deepThink.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(deepThink, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
          ],
          if (recommendation.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Lời khuyên dinh dưỡng:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(recommendation, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          ],
          const SizedBox(height: 12),
          Text(
            'Nội dung do AI tạo, chỉ mang tính tham khảo và có thể chưa chính xác. '
            'Không thay thế tư vấn của bác sĩ hoặc chuyên gia dinh dưỡng.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
