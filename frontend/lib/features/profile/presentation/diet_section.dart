import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

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

    return SectionCard(
      title: '5. Chế độ ăn & sở thích',
      accentColor: theme.colorScheme.secondary,
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: limitsSugar,
          onChanged: onLimitsSugarChanged,
          title: const Text('Tôi muốn giảm ngọt'),
          subtitle: const Text('Giới hạn đường tổng dưới 5% năng lượng, giống như khi có tiểu đường.'),
        ),
        for (final preference in FoodPreference.values)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: preferences.contains(preference),
            onChanged: (selected) => onPreferenceChanged(preference, selected: selected ?? false),
            title: Text(foodPreferenceLabel(preference)),
          ),
      ],
    );
  }
}
