import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/diary/food_logger.dart';
import 'package:fluw/core/diary/logged_food.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/meal_time.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/clock_provider.dart';
import 'package:fluw/core/widgets/meal_slot_picker.dart';

/// Pinned under the detail screen, as in the design, so adding never needs a scroll past the nutrient table. Starts on
/// the day and slot the diary asked for, otherwise on the slot happening now; off while the portion is not valid.
class AddToNoteBar extends ConsumerStatefulWidget {
  const AddToNoteBar({
    required this.name,
    required this.sourceFoodId,
    required this.facts,
    required this.portion,
    this.onAdded,
    super.key,
  });

  /// Null when the source has no name.
  final String? name;
  final String? sourceFoodId;
  final NutritionFacts facts;
  final double? portion;

  /// Called once the food is in the diary, e.g. to close the sheet the bar sits in.
  final VoidCallback? onAdded;

  @override
  ConsumerState<AddToNoteBar> createState() => _AddToNoteBarState();
}

class _AddToNoteBarState extends ConsumerState<AddToNoteBar> {
  late DiaryTarget _target = ref.read(diaryTargetProvider) ?? DiaryTarget.current(ref.read(clockProvider)());
  bool _isSaving = false;

  String _dayWords(CalendarDate day, CalendarDate currentDay) =>
      day == currentDay ? 'hôm nay' : 'ngày ${day.day}/${day.month}';

  Future<void> _add(double portion) async {
    final messenger = ScaffoldMessenger.of(context);
    // Read before the await: the user may leave the screen while the write runs, and `ref` is gone after that.
    final logger = ref.read(foodLoggerProvider);
    final diaryTarget = ref.read(diaryTargetProvider.notifier);
    final now = ref.read(clockProvider)();
    final name = widget.name ?? 'Món chưa có tên';
    final target = _target;
    final where = 'buổi ${mealSlotLabel(target.slot)} ${_dayWords(target.day, DiaryTarget.current(now).day)}';
    setState(() => _isSaving = true);
    try {
      await logger.log(
        LoggedFood(
          name: name,
          sourceFoodId: widget.sourceFoodId,
          facts: widget.facts,
          quantity: portion,
          eatenAt: eatenAtFor(day: target.day, slot: target.slot, now: now),
        ),
      );
    } on Object {
      messenger.showSnackBar(const SnackBar(content: Text('Không thêm được vào Nhật ký. Vui lòng thử lại.')));
      return;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
    diaryTarget.choose(null);
    messenger.showSnackBar(SnackBar(content: Text('Đã thêm $name vào $where')));
    if (mounted) {
      widget.onAdded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portion = widget.portion;
    final currentDay = DiaryTarget.current(ref.watch(clockProvider)()).day;

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
                      child: Text(
                        'Thêm vào Nhật ký ${_dayWords(_target.day, currentDay)}',
                        style: theme.textTheme.labelLarge,
                      ),
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
                MealSlotPicker(
                  selected: _target.slot,
                  onSelected: (slot) => setState(() => _target = DiaryTarget(day: _target.day, slot: slot)),
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
