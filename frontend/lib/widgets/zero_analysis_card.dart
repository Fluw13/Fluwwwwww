import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import 'common/info_chip.dart';
import 'common/section_title.dart';
import 'product/product_detail_metrics.dart';
import 'skeleton/skeleton_box.dart';

class ZeroAnalysisCard extends StatelessWidget {
  const ZeroAnalysisCard({super.key, required String this.deepThink, required String this.recommendation});

  /// Title, AI label and disclaimer are fixed; the analysis text is a placeholder.
  const ZeroAnalysisCard.loading({super.key}) : deepThink = null, recommendation = null;

  static const double _bodySize = 14;
  static const double _bodyHeight = 1.55;

  final String? deepThink;
  final String? recommendation;

  bool get hasContent => (deepThink ?? '').isNotEmpty || (recommendation ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final TextStyle body = TextStyle(fontSize: _bodySize, height: _bodyHeight, color: palette.textPrimary);
    final String? deepThink = this.deepThink;
    final String? recommendation = this.recommendation;
    final bool isLoading = deepThink == null;

    return Container(
      width: double.infinity,
      padding: ProductDetailMetrics.analysisCardPadding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 18, color: palette.accentText),
              const SectionTitle('Zero phân tích'),
              InfoChip(label: 'Do AI tạo', foreground: palette.textSecondary, background: palette.surfaceMuted),
            ],
          ),
          if (isLoading) ...const [
            SizedBox(height: AppSpacing.sm + 2),
            SkeletonBox.text(fontSize: _bodySize, lineHeight: _bodyHeight),
            SkeletonBox.text(fontSize: _bodySize, lineHeight: _bodyHeight),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: SkeletonBox.text(fontSize: _bodySize, lineHeight: _bodyHeight),
            ),
          ],
          if (deepThink != null && deepThink.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Text(deepThink, style: body),
          ],
          if (recommendation != null && recommendation.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Gợi ý', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            Text(recommendation, style: body),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nội dung do AI tạo, chỉ mang tính tham khảo và có thể chưa chính xác. '
            'Không thay thế tư vấn của bác sĩ hoặc chuyên gia dinh dưỡng.',
            style: TextStyle(color: palette.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
