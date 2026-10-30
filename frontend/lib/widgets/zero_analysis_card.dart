import 'package:flutter/material.dart';

import '../core/theme/fluw_palette.dart';

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
    final FluwPalette palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: palette.accentText),
              const SizedBox(width: 8),
              const Text(
                'Zero Deep Think',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Text(
                'Do AI tạo',
                style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (deepThink.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(deepThink, style: TextStyle(color: palette.textPrimary, fontSize: 14)),
          ],
          if (recommendation.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Lời khuyên dinh dưỡng:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(recommendation, style: TextStyle(color: palette.textPrimary, fontSize: 14)),
          ],
          const SizedBox(height: 12),
          Text(
            'Nội dung do AI tạo, chỉ mang tính tham khảo và có thể chưa chính xác. '
            'Không thay thế tư vấn của bác sĩ hoặc chuyên gia dinh dưỡng.',
            style: TextStyle(color: palette.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
