import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';
import 'package:fluw/features/profile/presentation/selectable_tile.dart';
import 'package:fluw/features/profile/presentation/setup_section_card.dart';

class DietSection extends StatelessWidget {
  const DietSection({
    required this.dietStyle,
    required this.onDietStyleChanged,
    required this.preferences,
    required this.onPreferenceChanged,
    required this.limitsSugar,
    required this.onLimitsSugarChanged,
    super.key,
  });

  final DietStyle dietStyle;
  final ValueChanged<DietStyle> onDietStyleChanged;
  final Set<FoodPreference> preferences;
  final void Function(FoodPreference preference, {required bool selected}) onPreferenceChanged;
  final bool limitsSugar;
  final ValueChanged<bool> onLimitsSugarChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SetupSectionCard(
      title: '5. Chế độ ăn & sở thích',
      markerColor: colors.secondary,
      children: [
        Text('Chế độ ăn', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final style in DietStyle.values)
              ChoiceChip(
                label: Text(dietStyleLabel(style)),
                selected: dietStyle == style,
                onSelected: (_) => onDietStyleChanged(style),
                // Filled like the design's chosen pill; the tick keeps the choice clear without colour.
                selectedColor: colors.primary,
                checkmarkColor: colors.onPrimary,
                backgroundColor: colors.surfaceContainerLow,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: dietStyle == style ? colors.onPrimary : colors.onSurface,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Dùng để gợi ý món phù hợp; không đổi chỉ tiêu calo và protein.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Thói quen ăn uống', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          tileColor: limitsSugar ? selectedTileColor(colors) : colors.surfaceContainerLow,
          value: limitsSugar,
          onChanged: onLimitsSugarChanged,
          title: Text('Tôi muốn giảm ngọt', style: theme.textTheme.titleSmall),
          subtitle: Text(
            'Mức gợi ý đường tổng dưới 5% năng lượng (dựa trên khuyến nghị đường tự do của WHO 2015).',
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final preference in FoodPreference.values)
          SelectableTile(
            value: preferences.contains(preference),
            onChanged: (selected) => onPreferenceChanged(preference, selected: selected),
            title: foodPreferenceLabel(preference),
          ),
      ],
    );
  }
}
