import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/diary/meal_slot_labels.dart';
import 'package:fluw/core/diary/note_day.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/core/widgets/empty_state.dart';
import 'package:fluw/features/note/data/note_providers.dart';
import 'package:fluw/features/note/data/note_repository.dart';
import 'package:fluw/features/note/domain/week.dart';
import 'package:fluw/features/note/presentation/day_summary_card.dart';
import 'package:fluw/features/note/presentation/edit_note_entry_sheet.dart';
import 'package:fluw/features/note/presentation/meal_slot_section.dart';
import 'package:fluw/features/note/presentation/week_strip.dart';

class NoteScreen extends ConsumerStatefulWidget {
  const NoteScreen({required this.onAddFood, super.key});

  /// Opens the search tab; food is added to the diary from its detail screen, on the day and slot chosen here.
  final VoidCallback onAddFood;

  @override
  ConsumerState<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends ConsumerState<NoteScreen> {
  CalendarDate? _selected;

  Future<void> _delete(NoteEntry entry) async {
    final repository = ref.read(noteRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repository.delete(entry.id);
    } on Object {
      messenger.showSnackBar(const SnackBar(content: Text('Không xóa được món. Vui lòng thử lại.')));
      return;
    }
    // Queued, never replaced: deleting a second food must not take away the first one's undo.
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã xóa ${entry.name}'),
        action: SnackBarAction(label: 'Hoàn tác', onPressed: () => _restore(repository, messenger, entry)),
      ),
    );
  }

  Future<void> _restore(NoteRepository repository, ScaffoldMessengerState messenger, NoteEntry entry) async {
    try {
      await repository.add(entry);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text('Không khôi phục được ${entry.name}. Vui lòng thêm lại.')));
    }
  }

  Future<void> _edit(NoteEntry entry) async {
    final edited = await showEditNoteEntrySheet(context, entry);
    if (edited == null || edited == entry || !mounted) {
      return;
    }
    final repository = ref.read(noteRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repository.update(edited);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text('Không sửa được ${entry.name}. Vui lòng thử lại.')));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã sửa ${entry.name}'),
        action: SnackBarAction(label: 'Hoàn tác', onPressed: () => _undoEdit(repository, messenger, entry)),
      ),
    );
  }

  Future<void> _undoEdit(NoteRepository repository, ScaffoldMessengerState messenger, NoteEntry original) async {
    try {
      await repository.update(original);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text('Không hoàn tác được ${original.name}. Vui lòng sửa lại.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final selected = _selected ?? today;
    final week = ref.watch(weekNoteEntriesProvider(mondayOf(selected)));
    final limits = ref.watch(personalLimitsProvider);
    final days = groupNoteEntries(week.value?.entries ?? const []);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Outside the loading state, so changing week keeps the row in place instead of a full-screen spinner.
        WeekStrip(
          selected: selected,
          today: today,
          daysWithEntries: {for (final candidate in days) candidate.date},
          onSelected: (value) => setState(() => _selected = value),
        ),
        const SizedBox(height: AppSpacing.md),
        ...week.when(
          skipLoadingOnReload: true,
          loading: () => [const Center(child: CircularProgressIndicator())],
          error: (error, stackTrace) => [
            const EmptyState(
              icon: Icons.error_outline,
              title: 'Không đọc được Nhật ký',
              message: 'Dữ liệu trên máy chưa đọc được.',
            ),
            Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(weekNoteEntriesProvider(mondayOf(selected))),
                child: const Text('Thử lại'),
              ),
            ),
          ],
          data: (window) => _dayContent(window.unreadableCount, days, selected, limits),
        ),
      ],
    );
  }

  List<Widget> _dayContent(int unreadableCount, List<NoteDay> days, CalendarDate selected, PersonalLimits limits) {
    final theme = Theme.of(context);
    final day = days.where((candidate) => candidate.date == selected).firstOrNull;
    final entryCount = day?.entriesBySlot.values.fold<int>(0, (sum, list) => sum + list.length) ?? 0;

    return [
      if (unreadableCount > 0) ...[
        Text(
          'Có $unreadableCount món trong tuần này không đọc được nên không tính vào tổng.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      DaySummaryCard(totals: day?.dayTotal ?? NutrientTotals.of(const []), entryCount: entryCount, limits: limits),
      for (final slot in mealSlotDisplayOrder) ...[
        const SizedBox(height: AppSpacing.md),
        MealSlotSection(
          slot: slot,
          entries: day?.entriesBySlot[slot] ?? const [],
          totals: day?.totalFor(slot) ?? NutrientTotals.of(const []),
          onEdit: _edit,
          onDelete: _delete,
          onAddFood: () {
            ref.read(diaryTargetProvider.notifier).choose(DiaryTarget(day: selected, slot: slot));
            widget.onAddFood();
          },
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      Text(
        'Số liệu là ước tính từ nguồn dữ liệu, không thay thế tư vấn y tế.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
    ];
  }
}
