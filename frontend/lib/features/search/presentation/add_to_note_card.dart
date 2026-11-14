import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/food_logger.dart';
import 'package:fluw/core/diary/logged_food.dart';
import 'package:fluw/core/diary/meal_placement.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/meal_time.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/search/domain/food_item.dart';

/// Adds the typed portion to today's diary. The slot starts at the current one; the button is off while the
/// portion is not a valid amount.
class AddToNoteCard extends ConsumerStatefulWidget {
  const AddToNoteCard({required this.item, required this.portion, super.key});

  final FoodItem item;
  final double? portion;

  @override
  ConsumerState<AddToNoteCard> createState() => _AddToNoteCardState();
}

class _AddToNoteCardState extends ConsumerState<AddToNoteCard> {
  late MealSlot _slot = placeMeal(DateTime.now()).slot;
  bool _isSaving = false;

  Future<void> _add(double portion) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = widget.item.name ?? 'Món chưa có tên';
    setState(() => _isSaving = true);
    try {
      await ref
          .read(foodLoggerProvider)
          .log(
            LoggedFood(
              name: name,
              sourceFoodId: widget.item.id,
              facts: widget.item.facts,
              quantity: portion,
              eatenAt: eatenAtFor(day: ref.read(todayProvider), slot: _slot, now: DateTime.now()),
            ),
          );
      messenger.showSnackBar(SnackBar(content: Text('Đã thêm $name vào buổi ${mealSlotLabel(_slot)} hôm nay')));
    } on Object {
      messenger.showSnackBar(const SnackBar(content: Text('Không thêm được vào Nhật ký. Vui lòng thử lại.')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final portion = widget.portion;

    return SectionCard(
      title: 'Thêm vào Nhật ký hôm nay',
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final slot in mealSlotDisplayOrder)
              ChoiceChip(
                label: Text(mealSlotLabel(slot)),
                tooltip: mealSlotHours(slot),
                selected: slot == _slot,
                onSelected: (_) => setState(() => _slot = slot),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: portion == null || _isSaving ? null : () => _add(portion),
          icon: const Icon(Icons.add),
          label: Text(_isSaving ? 'Đang thêm...' : 'Thêm vào Nhật ký'),
        ),
        if (portion == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('Nhập khẩu phần hợp lệ để thêm.', style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
