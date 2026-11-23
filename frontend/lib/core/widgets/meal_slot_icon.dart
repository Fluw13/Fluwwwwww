import 'package:flutter/material.dart';
import 'package:fluw/core/diary/meal_slot.dart';

/// The tinted icon tile of a meal slot, shared by Home and the diary. Decorative: the slot name is always written
/// next to it.
class MealSlotIcon extends StatelessWidget {
  const MealSlotIcon({required this.slot, this.size = 40, super.key});

  final MealSlot slot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, background, foreground) = switch (slot) {
      MealSlot.morning => (Icons.wb_twilight, scheme.tertiaryContainer, scheme.tertiary),
      MealSlot.afternoon => (Icons.wb_sunny_outlined, scheme.tertiaryContainer, scheme.tertiary),
      MealSlot.evening => (Icons.nightlight_round, scheme.secondaryContainer, scheme.secondary),
      MealSlot.night => (Icons.bedtime_outlined, scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(icon, color: foreground, size: size * 0.55),
      ),
    );
  }
}
