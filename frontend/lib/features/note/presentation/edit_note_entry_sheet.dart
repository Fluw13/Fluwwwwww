import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/clock_provider.dart';
import 'package:fluw/core/widgets/meal_slot_picker.dart';
import 'package:fluw/core/widgets/portion_input.dart';
import 'package:fluw/features/note/domain/entry_edit.dart';

/// Returns the edited entry, or null when the user cancels; the caller saves it.
Future<NoteEntry?> showEditNoteEntrySheet(BuildContext context, NoteEntry entry) => showModalBottomSheet<NoteEntry>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  builder: (context) => EditNoteEntrySheet(entry: entry),
);

class EditNoteEntrySheet extends ConsumerStatefulWidget {
  const EditNoteEntrySheet({required this.entry, super.key});

  final NoteEntry entry;

  @override
  ConsumerState<EditNoteEntrySheet> createState() => _EditNoteEntrySheetState();
}

class _EditNoteEntrySheetState extends ConsumerState<EditNoteEntrySheet> {
  late final TextEditingController _portion = TextEditingController(text: formatDecimal(widget.entry.quantity));
  late CalendarDate _day = widget.entry.placement.day;
  late MealSlot _slot = widget.entry.placement.slot;

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

  Future<void> _pickDay(CalendarDate currentDay) async {
    final last = DateTime(currentDay.year, currentDay.month, currentDay.day);
    final chosen = DateTime(_day.year, _day.month, _day.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: last,
      initialDate: chosen.isAfter(last) ? last : chosen,
      helpText: 'Chọn ngày ăn',
    );
    if (picked != null && mounted) {
      setState(() => _day = CalendarDate.fromDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final now = ref.watch(clockProvider)();
    final (amount, error) = parsePortion(_portion.text, entry.facts.unit);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sửa món', style: theme.textTheme.titleLarge),
            Text(entry.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            PortionInput(controller: _portion, unit: entry.facts.unit, errorText: error),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Text('Ngày ${_day.day}/${_day.month}/${_day.year}', style: theme.textTheme.labelLarge),
                TextButton(onPressed: () => _pickDay(DiaryTarget.current(now).day), child: const Text('Đổi ngày')),
              ],
            ),
            Text(
              'Bữa: ${mealSlotLabel(_slot)} (${mealSlotHours(_slot)})',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            MealSlotPicker(selected: _slot, onSelected: (slot) => setState(() => _slot = slot)),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: amount == null
                  ? null
                  : () =>
                        Navigator.of(context)
                            .pop(editNoteEntry(entry, quantity: amount, day: _day, slot: _slot, now: now)),
              child: const Text('Lưu thay đổi'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
          ],
        ),
      ),
    );
  }
}
