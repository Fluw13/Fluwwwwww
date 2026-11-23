import 'package:flutter/material.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/widgets/app_card.dart';
import 'package:fluw/core/widgets/meal_slot_icon.dart';
import 'package:fluw/features/note/presentation/note_entry_tile.dart';

class MealSlotSection extends StatelessWidget {
  const MealSlotSection({
    required this.slot,
    required this.entries,
    required this.totals,
    required this.onEdit,
    required this.onDelete,
    required this.onAddFood,
    super.key,
  });

  final MealSlot slot;
  final List<NoteEntry> entries;
  final NutrientTotals totals;
  final ValueChanged<NoteEntry> onEdit;
  final ValueChanged<NoteEntry> onDelete;
  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = theme.textTheme.value;
    final kcal = totals[Nutrient.energyKcal].knownSum;
    final protein = totals[Nutrient.proteinG].knownSum;
    final sugars = totals[Nutrient.sugarsG].knownSum;
    String grams(double? value) => value == null ? 'chưa có' : '${formatDecimal(value)} g';
    final separator = TextSpan(
      text: ' · ',
      style: value?.copyWith(color: scheme.onSurfaceVariant),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MealSlotIcon(slot: slot),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Semantics(header: true, child: Text(mealSlotLabel(slot), style: theme.textTheme.titleLarge)),
                        Text(mealSlotHours(slot), style: value?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                    if (entries.isEmpty)
                      Text('Chưa ghi món', style: theme.textTheme.bodySmall)
                    else
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: kcal == null ? 'Năng lượng chưa có' : '${formatWhole(kcal)} kcal',
                              style: value?.copyWith(color: scheme.tertiary),
                            ),
                            separator,
                            TextSpan(
                              text: 'Protein (đạm) ${grams(protein)}',
                              style: value?.copyWith(color: scheme.secondary),
                            ),
                            separator,
                            TextSpan(
                              text: 'Đường ${grams(sugars)}',
                              style: value?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          for (final entry in entries) ...[
            NoteEntryTile(entry: entry, onEdit: () => onEdit(entry), onDelete: () => onDelete(entry)),
            const SizedBox(height: AppSpacing.sm),
          ],
          TextButton.icon(
            onPressed: onAddFood,
            style: TextButton.styleFrom(
              backgroundColor: scheme.surfaceContainer,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: Text('Thêm món vào buổi ${mealSlotLabel(slot).toLowerCase()}'),
          ),
        ],
      ),
    );
  }
}
