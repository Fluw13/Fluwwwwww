import 'package:flutter/material.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/note/presentation/note_labels.dart';

class NoteEntryTile extends StatelessWidget {
  const NoteEntryTile({required this.entry, required this.onEdit, required this.onDelete, super.key});

  /// Wide enough for the edit and delete buttons; the calories sit above them.
  static const double _trailingWidth = 96;

  final NoteEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nutrients = entry.nutrients;
    final kcal = nutrients[Nutrient.energyKcal];
    final protein = nutrients[Nutrient.proteinG];
    final sugars = nutrients[Nutrient.sugarsG];
    final details = theme.textTheme.bodySmall;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm + AppSpacing.xs, AppSpacing.sm, 0, AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.inner),
      ),
      child: Row(
        children: [
          // Diary entries have no photo; a plain tile stands in for the design's food pictures.
          if (MediaQuery.textScalerOf(context).scale(1) <= 1.5) ...[
            ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                ),
                child: Icon(Icons.restaurant, size: 20, color: scheme.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: details,
                    children: [
                      TextSpan(
                        text:
                            '${timeLabel(entry.eatenAt)} · ${formatDecimal(entry.quantity)} ${entry.facts.unit.symbol} · ',
                      ),
                      TextSpan(
                        text: 'Protein (đạm) ${protein == null ? 'chưa có' : '${formatDecimal(protein)} g'}',
                        style: details?.copyWith(color: scheme.secondary, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' · Đường ${sugars == null ? 'chưa có' : '${formatDecimal(sugars)} g'}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _trailingWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm + AppSpacing.xs),
                  child: Text(
                    kcal == null ? 'Chưa có kcal' : '${formatWhole(kcal)} kcal',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(onPressed: onEdit, tooltip: 'Sửa ${entry.name}', icon: const Icon(Icons.edit_outlined)),
                    IconButton(onPressed: onDelete, tooltip: 'Xóa ${entry.name}', icon: const Icon(Icons.close)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
