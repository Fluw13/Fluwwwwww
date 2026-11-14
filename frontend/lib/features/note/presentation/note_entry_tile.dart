import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/note/domain/note_entry.dart';
import 'package:fluw/features/note/presentation/note_labels.dart';

class NoteEntryTile extends StatelessWidget {
  const NoteEntryTile({required this.entry, required this.onDelete, super.key});

  final NoteEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrients = entry.nutrients;
    final kcal = nutrients[Nutrient.energyKcal];
    final protein = nutrients[Nutrient.proteinG];
    final sugars = nutrients[Nutrient.sugarsG];
    final unit = entry.facts.unit == QuantityUnit.gram ? 'g' : 'ml';
    final details = [
      timeLabel(entry.eatenAt),
      '${formatDecimal(entry.quantity)} $unit',
      'Đạm ${protein == null ? 'chưa có' : '${formatDecimal(protein)} g'}',
      'Đường ${sugars == null ? 'chưa có' : '${formatDecimal(sugars)} g'}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: theme.textTheme.titleSmall),
                Text(details, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(
                  kcal == null ? 'Năng lượng chưa có dữ liệu' : '${formatWhole(kcal)} kcal',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
          IconButton(onPressed: onDelete, tooltip: 'Xóa ${entry.name}', icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
