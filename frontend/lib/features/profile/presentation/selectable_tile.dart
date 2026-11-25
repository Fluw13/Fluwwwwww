import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// A tick box on a tinted block, like the condition cards of the design; the block turns mint once ticked.
class SelectableTile extends StatelessWidget {
  const SelectableTile({required this.value, required this.onChanged, required this.title, this.subtitle, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CheckboxListTile(
        value: value,
        onChanged: (selected) => onChanged(selected ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
        tileColor: value ? selectedTileColor(theme.colorScheme) : theme.colorScheme.surfaceContainerLow,
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: subtitle == null ? null : Text(subtitle, style: theme.textTheme.bodySmall),
      ),
    );
  }
}

/// The mint of a ticked block, over the card colour.
Color selectedTileColor(ColorScheme colors) =>
    Color.alphaBlend(colors.primaryContainer.withValues(alpha: 0.3), colors.surfaceContainerLowest);
