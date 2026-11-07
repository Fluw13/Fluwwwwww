import 'package:flutter/material.dart';

import '../../content/fns_copy.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/fns_result.dart';

/// Takes the place of the score card when the backend did not score the product. It names the reason and
/// the missing data instead of showing a 0 or an empty ring.
class FnsNotScoredCard extends StatelessWidget {
  const FnsNotScoredCard({super.key, required this.fns});

  final FnsResult fns;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? missing = FnsCopy.missingFieldsText(fns.missingFields);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.info_outline, size: 18, color: palette.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  FnsCopy.notScoredTitle(fns),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(FnsCopy.notScoredReason(fns), style: TextStyle(color: palette.textPrimary, fontSize: 14, height: 1.5)),
          if (missing != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(missing, style: TextStyle(color: palette.textPrimary, fontSize: 14, height: 1.5)),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${FnsCopy.name} chỉ được hiển thị khi đủ dữ liệu. Thông tin dinh dưỡng bên dưới vẫn lấy từ Open Food Facts.',
            style: TextStyle(color: palette.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
