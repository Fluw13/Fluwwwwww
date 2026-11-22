import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/domain/quick_filter.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// "Lọc nhanh" pills with the design's reset link; a chosen pill takes the tinted container and a check.
class QuickFilterBar extends StatelessWidget {
  const QuickFilterBar({required this.selected, required this.onChanged, super.key});

  final Set<QuickFilter> selected;
  final ValueChanged<Set<QuickFilter>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Lọc nhanh (trong 100 g/ml)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            TextButton(onPressed: selected.isEmpty ? null : () => onChanged(const {}), child: const Text('Đặt lại')),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final filter in QuickFilter.values)
              FilterChip(
                label: Text(quickFilterLabel(filter)),
                selected: selected.contains(filter),
                showCheckmark: false,
                avatar: selected.contains(filter)
                    ? Icon(Icons.check_circle_outline, color: scheme.onSecondaryContainer)
                    : Center(
                        child: SizedBox.square(
                          dimension: AppSpacing.sm,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                shape: const StadiumBorder(),
                side: BorderSide.none,
                backgroundColor: scheme.surfaceContainer,
                selectedColor: scheme.secondaryContainer,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: WidgetStateColor.resolveWith(
                    (states) => states.contains(WidgetState.selected) ? scheme.onSecondaryContainer : scheme.onSurface,
                  ),
                ),
                onSelected: (isSelected) =>
                    onChanged(isSelected ? {...selected, filter} : ({...selected}..remove(filter))),
              ),
          ],
        ),
        if (selected.contains(QuickFilter.lowSugar))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(lowSugarDrinkNote, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}
