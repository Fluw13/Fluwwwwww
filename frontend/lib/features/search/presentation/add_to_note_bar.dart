import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/diary/food_logger.dart';
import 'package:fluw/core/diary/logged_food.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/meal_time.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/search/domain/food_item.dart';

/// Pinned under the detail screen, as in the design, so adding never needs a scroll past the nutrient table. Starts on
/// the day and slot the diary asked for, otherwise on the slot happening now; off while the portion is not valid.
class AddToNoteBar extends ConsumerStatefulWidget {
  const AddToNoteBar({required this.item, required this.portion, super.key});

  final FoodItem item;
  final double? portion;

  @override
  ConsumerState<AddToNoteBar> createState() => _AddToNoteBarState();
}

class _AddToNoteBarState extends ConsumerState<AddToNoteBar> {
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
    final currentDay = DiaryTarget.current(DateTime.now()).day;

    // Capped like Material's NavigationBar: a pinned bar that grew with the largest font sizes would cover the page.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Thêm vào Nhật ký ${_dayWords(_target.day)}', style: theme.textTheme.labelLarge),
                    ),
                    Text(
                      mealSlotLabel(_target.slot),
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                if (_target.day != currentDay)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => setState(() => _target = DiaryTarget(day: currentDay, slot: _target.slot)),
                      child: const Text('Chọn hôm nay'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final (index, slot) in mealSlotDisplayOrder.indexed) ...[
                      if (index > 0) const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _SlotSegment(
                          slot: slot,
                          isSelected: slot == _target.slot,
                          onTap: () => setState(() => _target = DiaryTarget(day: _target.day, slot: slot)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: portion == null || _isSaving ? null : () => _add(portion),
                  icon: const Icon(Icons.add),
                  label: Text(_isSaving ? 'Đang thêm...' : 'Thêm vào Nhật ký'),
                ),
                if (portion == null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Nhập khẩu phần hợp lệ để thêm.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotSegment extends StatelessWidget {
  const _SlotSegment({required this.slot, required this.isSelected, required this.onTap});

  final MealSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${mealSlotLabel(slot)}, ${mealSlotHours(slot)}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: isSelected ? theme.colorScheme.secondaryContainer : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: ConstrainedBox(
            // 48 dp: the minimum touch target.
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(mealSlotShortHours(slot), style: theme.textTheme.labelLarge?.copyWith(color: foreground)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
