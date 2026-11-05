import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/product/product_tags.dart';
import '../../models/score/additives_score.dart';
import '../common/labeled_value.dart';
import '../common/section_title.dart';

/// Additives by E-number and name. An empty list only means "no additives"
/// when the backend could verify the ingredient list; otherwise the data is
/// reported as missing.
class AdditivesSection extends StatelessWidget {
  const AdditivesSection({
    super.key,
    required this.additives,
    required this.score,
  });

  static const String noneVerified =
      'Không có phụ gia trong danh sách thành phần.';
  static const String note =
      'Theo danh sách thành phần trên Open Food Facts. Các phụ gia được liệt kê là chất được phép sử dụng.';

  final List<ProductAdditive> additives;
  final AdditivesScore score;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final bool verifiedNone =
        score.status == AdditivesStatus.computed && score.count == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          additives.isEmpty ? 'Phụ gia' : 'Phụ gia (${additives.length})',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (additives.isEmpty)
          Text(
            verifiedNone ? noneVerified : LabeledValue.missing,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: palette.textSecondary,
            ),
          )
        else
          for (final ProductAdditive additive in additives)
            _AdditiveRow(additive: additive),
        const SizedBox(height: AppSpacing.sm),
        Text(
          note,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AdditiveRow extends StatelessWidget {
  const _AdditiveRow({required this.additive});

  final ProductAdditive additive;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? name = additive.name;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                additive.code,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  name ?? 'Chưa có tên',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: name == null
                        ? palette.textSecondary
                        : palette.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
