import 'package:flutter/material.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/note_day.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';

/// Today's four meal slots in the design's order, each with what was logged or a way to log it.
class TodayMealsCard extends StatelessWidget {
  const TodayMealsCard({
    required this.day,
    required this.unreadableCount,
    required this.onAddFood,
    required this.onOpenNote,
    super.key,
  });

  final NoteDay? day;
  final int unreadableCount;
  final ValueChanged<MealSlot> onAddFood;
  final VoidCallback onOpenNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Bữa ăn hôm nay',
      children: [
        for (final slot in mealSlotDisplayOrder) ...[
          _SlotRow(slot: slot, day: day, onAdd: () => onAddFood(slot)),
          const Divider(height: AppSpacing.md),
        ],
        if (unreadableCount > 0)
          Text(
            'Có $unreadableCount món không đọc được nên không hiện ở đây.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: onOpenNote, child: const Text('Xem Nhật ký')),
        ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.day, required this.onAdd});

  final MealSlot slot;
  final NoteDay? day;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final entries = day?.entriesBySlot[slot] ?? const [];
    final total = day?.totalFor(slot)[Nutrient.energyKcal];
    final names = entries.take(2).map((entry) => entry.name).join(', ');
    final more = entries.length > 2 ? ' và ${entries.length - 2} món khác' : '';

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${mealSlotLabel(slot)} (${mealSlotHours(slot)})', style: theme.textTheme.labelLarge),
        Text(entries.isEmpty ? 'Chưa ghi món' : '$names$more', style: entries.isEmpty ? muted : null),
      ],
    );
    final Widget trailing = entries.isEmpty
        ? Semantics(
            label: 'Ghi món vào buổi ${mealSlotLabel(slot).toLowerCase()}',
            button: true,
            excludeSemantics: true,
            onTap: onAdd,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Ghi món'),
            ),
          )
        : Text(switch (total?.knownSum) {
            null => 'Chưa có kcal',
            // Some foods lack calories, so the real total is at least this much.
            final kcal => total!.isComplete ? '${formatWhole(kcal)} kcal' : '≥ ${formatWhole(kcal)} kcal',
          }, style: theme.textTheme.titleSmall);

    // With large text the button would squeeze the slot name into a sliver: put it under the name instead.
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          details,
          Align(alignment: AlignmentDirectional.centerEnd, child: trailing),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: details),
        const SizedBox(width: AppSpacing.sm),
        trailing,
      ],
    );
  }
}
