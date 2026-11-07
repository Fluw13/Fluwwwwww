import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../core/theme/score_colors.dart';
import '../../content/fns_copy.dart';
import '../../models/fns_result.dart';
import '../../models/score_level.dart';
import '../circular_score_ring.dart';
import '../common/info_chip.dart';
import '../skeleton/skeleton_box.dart';
import 'product_detail_metrics.dart';

/// Hero card of a scored product. Products without a score use FnsNotScoredCard instead, so no ring is
/// ever drawn for a missing score.
class ScoreSummaryCard extends StatelessWidget {
  const ScoreSummaryCard({super.key, required FnsResult this.fns});

  /// Same card while the score is loading: ring and level are placeholders.
  const ScoreSummaryCard.loading({super.key}) : fns = null;

  final FnsResult? fns;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final FnsResult? fns = this.fns;
    final double? score = fns?.score;

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
          if (score == null) const _ChipPlaceholder() else _LevelChip(score: score),
          const SizedBox(height: AppSpacing.md),
          // Every line below has the same height loading or loaded, so nothing jumps when the result
          // arrives; the data-dependent comparison group lives in FnsBreakdownCard.
          Text(
            FnsCopy.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textPrimary),
          ),
          Opacity(
            opacity: fns == null ? 0 : 1,
            child: Text(
              FnsCopy.statusLabel(fns?.status ?? FnsStatus.provisional),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w600, color: palette.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            FnsCopy.disclaimer(fns?.basis),
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

  final double score;

  @override
  Widget build(BuildContext context) {
    final ScoreLevel level = ScoreLevel.fromScore(score);
    final ScoreColors colors = context.palette.scoreColors(level);
    return InfoChip(label: level.label, foreground: colors.text, background: colors.container, emphasized: true);
  }
}

class _ChipPlaceholder extends StatelessWidget {
  const _ChipPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: InfoChip.verticalPadding),
      child: SkeletonBox.text(width: 64, fontSize: InfoChip.emphasizedFontSize, lineHeight: InfoChip.lineHeight),
    );
  }
}
