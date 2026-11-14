import 'package:flutter/material.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/note/domain/note_entry.dart';
import 'package:fluw/features/note/presentation/note_entry_tile.dart';

class MealSlotSection extends StatelessWidget {
  const MealSlotSection({
    required this.slot,
    required this.entries,
    required this.totals,
    required this.onDelete,
    required this.onAddFood,
    super.key,
  });

  final MealSlot slot;
  final List<NoteEntry> entries;
  final NutrientTotals totals;
  final ValueChanged<NoteEntry> onDelete;
  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kcal = totals[Nutrient.energyKcal].knownSum;
    final protein = totals[Nutrient.proteinG].knownSum;
    final sugars = totals[Nutrient.sugarsG].knownSum;
    String grams(double? value) => value == null ? 'chưa có' : '${formatDecimal(value)} g';

    return SectionCard(
      title: mealSlotLabel(slot),
      children: [
        Text(
          mealSlotHours(slot),
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (entries.isNotEmpty)
          Text(
            '${kcal == null ? 'Năng lượng chưa có' : '${formatWhole(kcal)} kcal'} · Đạm ${grams(protein)} · '
            'Đường ${grams(sugars)}',
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in entries) ...[
          NoteEntryTile(entry: entry, onDelete: () => onDelete(entry)),
          const SizedBox(height: AppSpacing.sm),
        ],
        OutlinedButton.icon(
          onPressed: onAddFood,
          icon: const Icon(Icons.add_circle_outline),
          label: Text('Thêm món vào buổi ${mealSlotLabel(slot).toLowerCase()}'),
        ),
      ],
    );
  }
}
