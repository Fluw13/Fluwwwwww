import 'package:flutter/material.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/note_day.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/app_card.dart';
import 'package:fluw/core/widgets/meal_slot_icon.dart';
import 'package:fluw/core/widgets/section_header.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Bữa ăn hôm nay',
          icon: Icons.schedule,
          trailing: TextButton(onPressed: onOpenNote, child: const Text('Xem Nhật ký')),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final slot in mealSlotDisplayOrder) ...[
          _SlotTile(slot: slot, day: day, onAdd: () => onAddFood(slot)),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (unreadableCount > 0)
          Text(
            'Có $unreadableCount món không đọc được nên không hiện ở đây.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.day, required this.onAdd});

  final MealSlot slot;
  final NoteDay? day;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = day?.entriesBySlot[slot] ?? const [];

    if (entries.isEmpty) {
      return AppCard(
        color: scheme.surfaceContainerLow,
        radius: AppRadius.inner,
        elevated: false,
        child: _EmptySlot(slot: slot, onAdd: onAdd),
      );
    }

    final total = day?.totalFor(slot)[Nutrient.energyKcal];
    final names = entries.take(2).map((entry) => entry.name).join(', ');
    final more = entries.length > 2 ? ' và ${entries.length - 2} món khác' : '';

    return AppCard(
      radius: AppRadius.inner,
      child: Row(
        children: [
          if (MediaQuery.textScalerOf(context).scale(1) <= 1.5) ...[
            MealSlotIcon(slot: slot, size: 56),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _SlotPill(slot: slot, background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
                    Text(switch (total?.knownSum) {
                      null => 'Chưa có kcal',
                      // Some foods lack calories, so the real total is at least this much.
                      final kcal => total!.isComplete ? '${formatWhole(kcal)} kcal' : '≥ ${formatWhole(kcal)} kcal',
                    }, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('$names$more', style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.slot, required this.onAdd});

  final MealSlot slot;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlotPill(slot: slot, background: scheme.surfaceContainerHighest, foreground: scheme.onSurfaceVariant),
        const SizedBox(height: AppSpacing.xs),
        Text('Chưa ghi món', style: theme.textTheme.bodySmall),
      ],
    );
    final button = Semantics(
      label: 'Ghi món vào buổi ${mealSlotLabel(slot).toLowerCase()}',
      button: true,
      excludeSemantics: true,
      onTap: onAdd,
      child: FilledButton.icon(
        onPressed: onAdd,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
        ),
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const Text('Ghi món'),
      ),
    );

    // With large text the button would squeeze the slot name into a sliver: put it under the name instead.
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          details,
          const SizedBox(height: AppSpacing.sm),
          Align(alignment: AlignmentDirectional.centerEnd, child: button),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: details),
        const SizedBox(width: AppSpacing.sm),
        button,
      ],
    );
  }
}

/// The slot name and hours in a pill, as in the design.
class _SlotPill extends StatelessWidget {
  const _SlotPill({required this.slot, required this.background, required this.foreground});

  final MealSlot slot;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        '${mealSlotLabel(slot)} (${mealSlotHours(slot)})',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}
