import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

/// The diet and eating habits as tags, like the design's "Phong cách & sở thích ăn". They only steer suggestions;
/// "Giảm ngọt" is shown with them because the user turns it on in the same place, though it lowers the sugar target.
class DietPreferencesCard extends StatelessWidget {
  const DietPreferencesCard({required this.dietary, required this.limitsSugar, super.key});

  final DietaryPreferences dietary;
  final bool limitsSugar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SectionCard(
      title: 'Chế độ ăn & sở thích',
      icon: Icons.restaurant_outlined,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _Tag(
              icon: Icons.eco_outlined,
              label: dietStyleLabel(dietary.dietStyle),
              background: colors.primaryContainer.withValues(alpha: 0.45),
              foreground: colors.onPrimaryContainer,
            ),
            if (limitsSugar) const _Tag(icon: Icons.water_drop_outlined, label: 'Giảm ngọt'),
            for (final preference in FoodPreference.values)
              if (dietary.preferences.contains(preference))
                _Tag(icon: _preferenceIcon(preference), label: foodPreferenceLabel(preference)),
          ],
        ),
      ],
    );
  }

  static IconData _preferenceIcon(FoodPreference preference) => switch (preference) {
    FoodPreference.noOrganMeat => Icons.block,
    FoodPreference.steamedOrBoiled => Icons.soup_kitchen_outlined,
    FoodPreference.likesNuts => Icons.spa_outlined,
  };
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, this.background, this.foreground});

  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = this.foreground ?? colors.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Color.alphaBlend(background ?? colors.surfaceContainerLow, colors.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 18, color: foreground)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: foreground)),
          ),
        ],
      ),
    );
  }
}
