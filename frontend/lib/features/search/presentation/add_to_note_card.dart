import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/diary/food_logger.dart';
import 'package:fluw/core/diary/logged_food.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/meal_time.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/search/domain/food_item.dart';

/// Adds the typed portion to the diary. Starts on the day and slot the diary asked for, otherwise on the slot
/// happening now; the button is off while the portion is not a valid amount.
class AddToNoteCard extends ConsumerStatefulWidget {
  const AddToNoteCard({required this.item, required this.portion, super.key});

  final FoodItem item;
  final double? portion;

  @override
  ConsumerState<AddToNoteCard> createState() => _AddToNoteCardState();
}

class _AddToNoteCardState extends ConsumerState<AddToNoteCard> {
  late DiaryTarget _target = ref.read(diaryTargetProvider) ?? DiaryTarget.current(DateTime.now());
  bool _isSaving = false;

  String _dayWords(CalendarDate day) =>
      day == DiaryTarget.current(DateTime.now()).day ? 'hôm nay' : 'ngày ${day.day}/${day.month}';

  Future<void> _add(double portion) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = widget.item.name ?? 'Món chưa có tên';
    final target = _target;
    final where = 'buổi ${mealSlotLabel(target.slot)} ${_dayWords(target.day)}';
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
              eatenAt: eatenAtFor(day: target.day, slot: target.slot, now: DateTime.now()),
            ),
          );
      ref.read(diaryTargetProvider.notifier).choose(null);
      messenger.showSnackBar(SnackBar(content: Text('Đã thêm $name vào $where')));
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
    final theme = Theme.of(context);
    final portion = widget.portion;
    final current = DiaryTarget.current(DateTime.now());

    return SectionCard(
      title: 'Thêm vào Nhật ký ${_dayWords(_target.day)}',
      children: [
        if (_target.day != current.day)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => _target = DiaryTarget(day: current.day, slot: _target.slot)),
              child: const Text('Chọn hôm nay'),
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final slot in mealSlotDisplayOrder)
              ChoiceChip(
                label: Text(mealSlotLabel(slot)),
                tooltip: mealSlotHours(slot),
                selected: slot == _target.slot,
                onSelected: (_) => setState(() => _target = DiaryTarget(day: _target.day, slot: slot)),
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
            child: Text('Nhập khẩu phần hợp lệ để thêm.', style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}
