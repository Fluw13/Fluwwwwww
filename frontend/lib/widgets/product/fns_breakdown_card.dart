import 'package:flutter/material.dart';

import '../../content/fns_copy.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/fns_result.dart';
import '../common/section_title.dart';
import 'product_detail_metrics.dart';

/// Shows how the backend reached the score: points added by each baseline nutrient, points removed by
/// each modifier, and the caveats of the data. Nothing is recalculated here.
class FnsBreakdownCard extends StatelessWidget {
  const FnsBreakdownCard({super.key, required this.fns, this.values = const {}});

  final FnsResult fns;

  /// Optional label value per component (e.g. "12 g"), shown next to its name.
  final Map<String, String> values;

  static const List<String> _modifiers = ['fvnl', 'protein', 'fiber'];

  String _baselinePoints(String component) {
    final int? points = fns.componentPoints[component];
    return points == null ? FnsCopy.unknownPoints : '+$points';
  }

  String _modifierPoints(String component) {
    final bool counted = switch (component) {
      'protein' => fns.proteinEligible != false,
      'fiber' => fns.fiberEligible,
      _ => true,
    };
    if (!counted) return FnsCopy.notCounted;
    final int? points = fns.componentPoints[component];
    return points == null ? FnsCopy.unknownPoints : '−$points';
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final TextStyle note = TextStyle(fontSize: 12, height: 1.4, color: palette.textSecondary);
    final String? missing = FnsCopy.missingFieldsText(fns.missingFields);
    final String? category = FnsCopy.categoryLabel(fns.category);
    final int? rawScore = fns.rawScore;

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
          Row(
            children: [
              Icon(Icons.calculate_outlined, size: 18, color: palette.accentText),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: SectionTitle(FnsCopy.breakdownTitle)),
            ],
          ),
          if (category != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Nhóm so sánh: $category',
              style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: palette.textPrimary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(FnsCopy.breakdownIntro, style: note),
          const SizedBox(height: AppSpacing.sm),
          for (final String component in fns.baselineComponents)
            _PointsRow(
              label: FnsCopy.componentLabel(component),
              value: values[component],
              points: _baselinePoints(component),
            ),
          for (final String component in _modifiers)
            _PointsRow(
              label: FnsCopy.componentLabel(component),
              value: values[component],
              points: _modifierPoints(component),
            ),
          if (rawScore != null) ...[
            Divider(color: palette.border, height: AppSpacing.lg),
            _PointsRow(label: 'Tổng điểm', points: '$rawScore', emphasized: true),
          ],
          for (final String text in [?missing, ...FnsCopy.limitationNotes(fns)])
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('• $text', style: note),
            ),
        ],
      ),
    );
  }
}

class _PointsRow extends StatelessWidget {
  const _PointsRow({required this.label, required this.points, this.value, this.emphasized = false});

  final String label;
  final String? value;
  final String points;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? value = this.value;
    final FontWeight weight = emphasized ? FontWeight.w700 : FontWeight.w500;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  style: TextStyle(fontWeight: weight, color: palette.textPrimary),
                  children: [
                    if (value != null)
                      TextSpan(
                        text: '  $value',
                        style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              points,
              style: TextStyle(fontSize: 14, height: 1.4, fontWeight: weight, color: palette.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
