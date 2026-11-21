import 'package:flutter/material.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/portion_input.dart';
import 'package:fluw/features/search/presentation/add_to_note_bar.dart';

/// Logs a food from the diary again with the numbers saved back then: no search, works offline.
Future<void> showRecentFoodSheet(BuildContext context, NoteEntry food) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  builder: (context) => RecentFoodSheet(food: food),
);

class RecentFoodSheet extends StatefulWidget {
  const RecentFoodSheet({required this.food, super.key});

  final NoteEntry food;

  @override
  State<RecentFoodSheet> createState() => _RecentFoodSheetState();
}

class _RecentFoodSheetState extends State<RecentFoodSheet> {
  late final TextEditingController _portion = TextEditingController(text: formatDecimal(widget.food.quantity));

  @override
  void initState() {
    super.initState();
    _portion.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _portion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = widget.food;
    final (amount, error) = parsePortion(_portion.text, food.facts.unit);
    final kcal = amount == null ? null : food.facts.forQuantity(amount)[Nutrient.energyKcal];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(food.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Dùng số liệu đã lưu lần trước.${switch ((amount, kcal)) {
                      (null, _) => '',
                      (_, null) => ' Món này chưa có số liệu năng lượng.',
                      (_, final kcal?) => ' Khẩu phần này: ${formatWhole(kcal)} kcal.',
                    }}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PortionInput(controller: _portion, unit: food.facts.unit, errorText: error),
                ],
              ),
            ),
          ),
          AddToNoteBar(
            name: food.name,
            sourceFoodId: food.sourceFoodId,
            facts: food.facts,
            portion: amount,
            onAdded: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
