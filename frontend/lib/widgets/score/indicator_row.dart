import 'package:flutter/material.dart';

import '../../core/format/score_format.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/score/score_indicator.dart';

/// One nutrition indicator, laid out on several short lines so it fits a
/// 360 dp screen at large text sizes. Read as a single item by screen readers.
class IndicatorRow extends StatelessWidget {
  const IndicatorRow({super.key, required this.indicator});

  final ScoreIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? range = ScoreFormat.range(indicator.range, indicator.unit);
    final String? note = indicator.note;
    final bool isNegative = indicator.effect == IndicatorEffect.negative;
    final TextStyle detail = TextStyle(
      fontSize: 13,
      height: 1.45,
      color: palette.textSecondary,
    );

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNegative ? Icons.remove : Icons.add,
                size: 16,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        indicator.label,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ScoreFormat.points(
                          indicator.points,
                          indicator.maxPoints,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(ScoreFormat.indicatorMeasure(indicator), style: detail),
                  if (range != null)
                    Text('Khoảng ngưỡng: $range', style: detail),
                  Text(
                    '${ScoreFormat.effect(indicator.effect)} · ${ScoreFormat.indicatorStatus(indicator.status)}',
                    style: detail.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (note != null) Text(note, style: detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
