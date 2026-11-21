import 'package:flutter/material.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// The design's four short hour cells ("06–12h"...). Callers show [mealSlotLabel] of the choice next to it.
class MealSlotPicker extends StatelessWidget {
  const MealSlotPicker({required this.selected, required this.onSelected, super.key});

  final MealSlot selected;
  final ValueChanged<MealSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, slot) in mealSlotDisplayOrder.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _SlotSegment(slot: slot, isSelected: slot == selected, onTap: () => onSelected(slot)),
          ),
        ],
      ],
    );
  }
}

class _SlotSegment extends StatelessWidget {
  const _SlotSegment({required this.slot, required this.isSelected, required this.onTap});

  final MealSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Same as the selected day in the diary's week row: a strong fill, not a pale tint, so the choice never depends
    // on telling two light colours apart.
    final foreground = isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${mealSlotLabel(slot)}, ${mealSlotHours(slot)}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: ConstrainedBox(
            // 48 dp: the minimum touch target.
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(
                    mealSlotShortHours(slot),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: isSelected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
