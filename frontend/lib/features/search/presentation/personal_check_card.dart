import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/fluw_thresholds.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/search/domain/food_assessment.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// Compares the food with the user's profile. Every statement says what the data allows and no more: an empty
/// allergen list is never presented as "safe", and an unreadable profile is said out loud.
class PersonalCheckCard extends StatelessWidget {
  const PersonalCheckCard({
    required this.allergens,
    required this.shares,
    required this.limits,
    required this.hasPortion,
    required this.isLoadingAllergens,
    super.key,
  });

  final AllergenCheck allergens;
  final List<PortionShare> shares;
  final PersonalLimits limits;

  /// False while the portion field holds no valid amount, so [shares] is empty for that reason and not for lack of
  /// data.
  final bool hasPortion;
  final bool isLoadingAllergens;

  String _allergenName(String tag) => limits.allergenNames[tag] ?? tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return SectionCard(
      title: 'Đối chiếu hồ sơ của bạn',
      children: [
        ...switch (limits.profileStatus) {
          ProfileStatus.loading => [const LinearProgressIndicator()],
          ProfileStatus.unreadable => [
            _Notice(
              icon: Icons.error_outline,
              color: theme.colorScheme.error,
              text:
                  'Không đọc được hồ sơ trên máy nên chưa đối chiếu được dị ứng và chỉ tiêu. Hãy mở tab Hồ Sơ để '
                  'nhập lại; trong lúc đó hãy tự đọc nhãn sản phẩm.',
            ),
          ],
          ProfileStatus.none => [
            Text('Thiết lập hồ sơ để Fluw cảnh báo dị ứng và tính phần trăm chỉ tiêu mỗi ngày.', style: muted),
          ],
          ProfileStatus.loaded => _loadedContent(theme, muted),
        },
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ước tính từ dữ liệu nguồn, không thay thế tư vấn y tế.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  List<Widget> _loadedContent(ThemeData theme, TextStyle? muted) {
    final hasAllergies = limits.severeAllergenTags.isNotEmpty || limits.mildAllergenTags.isNotEmpty;
    final hasLimits = limits.dailyKcal != null || limits.sodiumMaxMg != null;
    return [
      if (hasAllergies) ...[
        if (isLoadingAllergens)
          Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Đang tải thông tin dị ứng của sản phẩm...', style: muted),
                const SizedBox(height: AppSpacing.xs),
                const LinearProgressIndicator(),
              ],
            ),
          )
        else
          _allergenNotice(theme),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (shares.isNotEmpty) ...[
        Text('Khẩu phần này chiếm trong chỉ tiêu cả ngày:', style: theme.textTheme.bodyMedium),
        for (final share in shares) _ShareRow(share: share),
      ] else if (!hasLimits)
        Text(
          'Hồ sơ hiện chưa có chỉ tiêu mỗi ngày (dưới 18 tuổi, mang thai hoặc cho con bú, hoặc hồ sơ cần sửa).',
          style: muted,
        )
      else if (!hasPortion)
        Text('Nhập khẩu phần hợp lệ để so với chỉ tiêu.', style: muted)
      else
        Text('Chưa đủ số liệu của món để so với chỉ tiêu.', style: muted),
    ];
  }

  Widget _allergenNotice(ThemeData theme) {
    return switch (allergens) {
      AllergensUnknown() => _Notice(
        icon: Icons.help_outline,
        color: theme.colorScheme.onSurfaceVariant,
        text: 'Nguồn này không có dữ liệu dị ứng. Hãy đọc nhãn sản phẩm.',
      ),
      NoListedAllergenMatch(:final recordedTagCount) => _Notice(
        icon: Icons.info_outline,
        color: theme.colorScheme.onSurfaceVariant,
        text: recordedTagCount == 0
            ? 'Open Food Facts chưa ghi thành phần dị ứng nào cho sản phẩm này. Hãy đọc nhãn sản phẩm.'
            : 'Không thấy nhóm bạn dị ứng trong danh sách đã ghi. Danh sách có thể thiếu, hãy đọc nhãn.',
      ),
      AllergenMatch(:final severe, :final mild) => _Notice(
        icon: Icons.gpp_maybe_outlined,
        color: severe.isNotEmpty ? theme.colorScheme.error : theme.colorScheme.tertiary,
        text: [
          if (severe.isNotEmpty) 'Có thành phần bạn dị ứng nặng: ${severe.map(_allergenName).join(', ')}.',
          if (mild.isNotEmpty) 'Có thành phần bạn dị ứng nhẹ: ${mild.map(_allergenName).join(', ')}.',
        ].join(' '),
      ),
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

  String _amount(double value) => formatShownAmount(share.nutrient, value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrient = share.nutrient;
    final percent = percentAsShown(nutrient, amount: share.amount, target: share.dailyLimit);
    final isOver = isOverAsShown(nutrient, amount: share.amount, target: share.dailyLimit);
    // Calories are a target, not a limit: going over is information, not a warning.
    final isTarget = nutrient == Nutrient.energyKcal;
    // Total sugars has a suggestion, not a limit: the warning colour, never the error red.
    final isSuggestion = nutrient == Nutrient.sugarsG;
    final isWarning = !isTarget && (isOver || share.isWatched && share.share >= watchedPortionShare);
    final color = isWarning ? (isSuggestion ? theme.colorScheme.tertiary : theme.colorScheme.error) : null;
    final notes = [if (isSuggestion) 'mức gợi ý', if (share.isWatched) 'bạn đang theo dõi'];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.sm,
            children: [
              Text(
                '${nutrientLabel(nutrient)}${notes.isEmpty ? '' : ' (${notes.join(', ')})'}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '$percent% · ${_amount(share.amount)}/${_amount(share.dailyLimit)} ${nutrientUnit(nutrient)}',
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
            Text(switch (nutrient) {
              Nutrient.energyKcal => 'Vượt mục tiêu calo cả ngày.',
              Nutrient.sugarsG => 'Cao hơn mức gợi ý cả ngày.',
              _ => 'Vượt giới hạn cả ngày.',
            }, style: theme.textTheme.bodySmall?.copyWith(color: color ?? theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
