import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/diary/recent_foods_reader.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// "Món đã ăn gần đây": foods from the diary, newest first. Shows nothing while loading, on error or when the diary is
/// empty; it only saves a search.
class RecentFoodsSection extends ConsumerWidget {
  const RecentFoodsSection({required this.onSelected, super.key});

  final ValueChanged<NoteEntry> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foods = ref.watch(recentFoodsProvider).value ?? const [];
    if (foods.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Món đã ăn gần đây', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final food in foods)
            Card(
              child: ListTile(
                title: Text(food.name),
                subtitle: Text(_lastTime(food)),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => onSelected(food),
              ),
            ),
        ],
      ),
    );
  }

  static String _lastTime(NoteEntry food) {
    final kcal = food.nutrients[Nutrient.energyKcal];
    return 'Lần trước ${formatDecimal(food.quantity)} ${food.facts.unit.symbol} · '
        '${kcal == null ? 'chưa có số liệu năng lượng' : '${formatWhole(kcal)} kcal'}';
  }
}
