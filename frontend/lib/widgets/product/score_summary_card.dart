import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../core/theme/score_colors.dart';
import '../../models/score_level.dart';
import '../circular_score_ring.dart';
import '../common/info_chip.dart';
import '../skeleton/skeleton_box.dart';
import 'product_detail_metrics.dart';

class ScoreSummaryCard extends StatelessWidget {
  const ScoreSummaryCard({super.key, required int this.score});

  /// Same card while the score is loading: ring and level are placeholders.
  const ScoreSummaryCard.loading({super.key}) : score = null;

  final int? score;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final int? score = this.score;

    return Container(
      width: double.infinity,
      padding: ProductDetailMetrics.scoreCardPadding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          if (score == null)
            const SkeletonBox.circle(size: ProductDetailMetrics.scoreRingSize)
          else
            CircularScoreRing(score: score, size: ProductDetailMetrics.scoreRingSize),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (score == null) const _LevelChipPlaceholder() else _LevelChip(score: score),
              InfoChip(label: 'Do AI tạo', foreground: palette.textSecondary, background: palette.surfaceMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Zero chấm theo thành phần và dinh dưỡng trên 100 g. Chỉ mang tính tham khảo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final ScoreLevel level = ScoreLevel.fromScore(score);
    final ScoreColors colors = context.palette.scoreColors(level);
    return InfoChip(label: level.label, foreground: colors.text, background: colors.container, emphasized: true);
  }
}

class _LevelChipPlaceholder extends StatelessWidget {
  const _LevelChipPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: InfoChip.verticalPadding),
      child: SkeletonBox.text(width: 64, fontSize: InfoChip.emphasizedFontSize, lineHeight: InfoChip.lineHeight),
    );
  }
}
