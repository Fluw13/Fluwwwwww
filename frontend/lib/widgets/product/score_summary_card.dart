import 'package:flutter/material.dart';

import '../../core/format/score_format.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/score/fluw_score.dart';
import '../../models/score/nutrition_score.dart';
import '../circular_score_ring.dart';
import '../common/info_chip.dart';
import '../score/missing_data_list.dart';
import '../score/score_components.dart';
import '../score/score_level_style.dart';
import '../skeleton/skeleton_box.dart';
import 'product_detail_metrics.dart';

/// The Fluw score computed by the backend: total and level, component scores
/// with their weights, the calculation and the formula version. Without a
/// total it says so and lists what is missing instead of drawing a ring.
class ScoreSummaryCard extends StatelessWidget {
  const ScoreSummaryCard({
    super.key,
    required FluwScore this.score,
    required this.onExplain,
  });

  /// Same card while the score is loading: numbers and texts are placeholders.
  const ScoreSummaryCard.loading({super.key}) : score = null, onExplain = null;

  static const String unavailableTitle = 'Chưa đủ dữ liệu để tính điểm tổng';
  static const String explainLabel = 'Cách Fluw tính điểm';
  static const double _calculationSize = 13;
  static const double _versionSize = 12;
  static const double _lineHeight = 1.4;

  final FluwScore? score;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final FluwScore? score = this.score;
    final TextStyle calculationStyle = TextStyle(
      fontSize: _calculationSize,
      height: _lineHeight,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
    );
    final TextStyle versionStyle = TextStyle(
      fontSize: _versionSize,
      height: _lineHeight,
      color: palette.textSecondary,
    );

    final List<Widget> children;
    if (score == null) {
      children = const [
        SkeletonBox.circle(size: ProductDetailMetrics.scoreRingSize),
        SizedBox(height: AppSpacing.md),
        _LevelChipPlaceholder(),
        SizedBox(height: AppSpacing.lg),
        ScoreComponents.loading(),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox.text(
          width: 210,
          fontSize: _calculationSize,
          lineHeight: _lineHeight,
        ),
        SkeletonBox.text(
          width: 140,
          fontSize: _versionSize,
          lineHeight: _lineHeight,
        ),
      ];
    } else {
      final String? calculation = ScoreFormat.calculation(score);
      final String? version = score.version;
      children = [
        if (score.total.isAvailable)
          _TotalScore(score: score)
        else
          _UnavailableTotal(score: score),
        const SizedBox(height: AppSpacing.lg),
        ScoreComponents(score: score),
        if (!score.total.isAvailable)
          Text(
            'Đây là điểm thành phần, chưa phải Điểm Fluw tổng.',
            textAlign: TextAlign.center,
            style: versionStyle,
          ),
        if (calculation != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            calculation,
            textAlign: TextAlign.center,
            style: calculationStyle,
          ),
        ],
        if (version != null)
          Text(
            'Công thức $version',
            textAlign: TextAlign.center,
            style: versionStyle,
          ),
      ];
    }

    final Widget explainButton = TextButton.icon(
      onPressed: onExplain,
      icon: const Icon(Icons.calculate_outlined, size: 18),
      label: const Text(explainLabel),
    );

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
          ...children,
          const SizedBox(height: AppSpacing.sm),
          if (score == null)
            ExcludeSemantics(child: explainButton)
          else
            explainButton,
        ],
      ),
    );
  }
}

class _TotalScore extends StatelessWidget {
  const _TotalScore({required this.score});

  final FluwScore score;

  @override
  Widget build(BuildContext context) {
    final int value = score.total.value!;
    final String? label = score.total.label;
    final ScoreLevelStyle style = ScoreLevelStyle.of(
      context,
      score.total.level,
    );
    final String spoken = label == null
        ? 'Điểm tổng $value trên 100'
        : 'Điểm tổng $value trên 100, mức $label';

    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Column(
        children: [
          CircularScoreRing(
            score: value,
            colors: style.colors,
            size: ProductDetailMetrics.scoreRingSize,
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoChip(
              label: label,
              icon: style.icon,
              foreground: style.colors.text,
              background: style.colors.container,
              emphasized: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _UnavailableTotal extends StatelessWidget {
  const _UnavailableTotal({required this.score});

  final FluwScore score;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final List<String> reasons = [
      if (score.nutrition.status == NutritionStatus.notApplicable)
        'Cách tính điểm dinh dưỡng không áp dụng cho loại sản phẩm này.',
    ];
    final List<String> missing = [for (final item in score.missing) item.label];

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.hourglass_empty,
            size: 28,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            ScoreSummaryCard.unavailableTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final String reason in reasons) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: palette.textPrimary,
            ),
          ),
        ],
        if (missing.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          MissingDataList(labels: missing, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _LevelChipPlaceholder extends StatelessWidget {
  const _LevelChipPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: InfoChip.verticalPadding),
      child: SkeletonBox.text(
        width: 64,
        fontSize: InfoChip.emphasizedFontSize,
        lineHeight: InfoChip.lineHeight,
      ),
    );
  }
}
