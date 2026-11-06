import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

/// Shown on Home until the first scan, to explain what Zero does.
class ZeroIntroCard extends StatelessWidget {
  const ZeroIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: palette.accentText),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Trợ lý Zero',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quét mã vạch đồ ăn hoặc thức uống để xem Điểm Fluw từ 0 đến 100, tính từ dữ liệu Open Food Facts '
            'theo công thức công khai. Bấm "Hỏi Zero" để AI giải thích ngắn gọn vì sao có điểm đó.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
