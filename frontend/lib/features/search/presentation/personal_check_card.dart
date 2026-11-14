import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/search/domain/food_assessment.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// Compares the food with the user's profile. Every statement says what the data allows and no more: an empty
/// allergen list is never presented as "safe".
class PersonalCheckCard extends StatelessWidget {
  const PersonalCheckCard({
    required this.allergens,
    required this.shares,
    required this.limits,
    required this.isLoadingAllergens,
    super.key,
  });

  final AllergenCheck allergens;
  final List<PortionShare> shares;
  final PersonalLimits limits;
  final bool isLoadingAllergens;

  String _allergenName(String tag) => limits.allergenNames[tag] ?? tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAllergies = limits.severeAllergenTags.isNotEmpty || limits.mildAllergenTags.isNotEmpty;
    final hasLimits = limits.dailyKcal != null || limits.sodiumMaxMg != null;

    return SectionCard(
      title: 'Đối chiếu hồ sơ của bạn',
      children: [
        if (isLoadingAllergens) const LinearProgressIndicator() else if (hasAllergies) _allergenMessage(theme),
        if (hasAllergies) const SizedBox(height: AppSpacing.sm),
        if (shares.isNotEmpty) ...[
          Text('Khẩu phần này chiếm trong chỉ tiêu cả ngày:', style: theme.textTheme.bodyMedium),
          for (final share in shares) _ShareRow(share: share),
        ] else if (!hasLimits)
          Text(
            'Thiết lập hồ sơ (từ 18 tuổi) để xem món này chiếm bao nhiêu chỉ tiêu mỗi ngày.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          Text(
            'Chưa đủ số liệu của món để so với chỉ tiêu.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ước tính từ dữ liệu nguồn, không thay thế tư vấn y tế.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _allergenMessage(ThemeData theme) {
    final (icon, color, text) = switch (allergens) {
      AllergensUnknown() => (
        Icons.help_outline,
        theme.colorScheme.onSurfaceVariant,
        'Nguồn này không có dữ liệu dị ứng. Hãy đọc nhãn sản phẩm.',
      ),
      NoListedAllergenMatch(:final recordedTagCount) => (
        Icons.info_outline,
        theme.colorScheme.onSurfaceVariant,
        recordedTagCount == 0
            ? 'Open Food Facts chưa ghi thành phần dị ứng nào cho sản phẩm này. Hãy đọc nhãn sản phẩm.'
            : 'Không thấy nhóm bạn dị ứng trong danh sách đã ghi. Danh sách có thể thiếu, hãy đọc nhãn.',
      ),
      AllergenMatch(:final severe, :final mild) => (
        Icons.gpp_maybe_outlined,
        severe.isNotEmpty ? theme.colorScheme.error : theme.colorScheme.tertiary,
        [
          if (severe.isNotEmpty) 'Có thành phần bạn dị ứng nặng: ${severe.map(_allergenName).join(', ')}.',
          if (mild.isNotEmpty) 'Có thành phần bạn dị ứng nhẹ: ${mild.map(_allergenName).join(', ')}.',
        ].join(' '),
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.share});

  final PortionShare share;

  // kcal and mg read better as whole numbers (2,083 kcal); grams keep one decimal.
  String _amount(double value) => switch (share.nutrient) {
    Nutrient.energyKcal || Nutrient.sodiumMg => formatWhole(value),
    _ => formatDecimal(value),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (share.share * 100).round();
    final isOver = share.share > 1;
    final color = isOver || share.isWatched && share.share >= 0.5 ? theme.colorScheme.error : null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${nutrientLabel(share.nutrient)}${share.isWatched ? ' (theo dõi theo bệnh nền)' : ''}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '$percent% · ${_amount(share.amount)}/${_amount(share.dailyLimit)} ${nutrientUnit(share.nutrient)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // The bar always has the number next to it, so the information never relies on colour alone.
          LinearProgressIndicator(
            value: share.share.clamp(0, 1).toDouble(),
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          if (isOver)
            Text('Vượt giới hạn cả ngày.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
        ],
      ),
    );
  }
}
