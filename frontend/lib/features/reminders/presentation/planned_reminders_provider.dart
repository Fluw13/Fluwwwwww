import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/diary_day.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/time/clock_provider.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/reminders/data/reminder_settings_controller.dart';
import 'package:fluw/features/reminders/domain/reminder_message.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';

/// The reminders that should be scheduled now. Null while today's diary is loading or could not be read: the
/// reminders already scheduled are then kept instead of being replaced with texts built on missing data.
final plannedRemindersProvider = Provider<List<PlannedReminder>?>((ref) {
  final settings = ref.watch(reminderSettingsProvider);
  if (!settings.enabled) {
    return const [];
  }
  final today = ref.watch(todayProvider);
  final diary = ref.watch(diaryDayProvider(today));
  if (diary.hasError || !diary.hasValue) {
    return null;
  }
  final day = diary.requireValue;
  return planReminders(
    settings: settings,
    now: ref.watch(clockProvider)(),
    today: today,
    todayIntake: DayIntake(
      totals: day.day?.dayTotal ?? NutrientTotals.of(const []),
      entryCount: day.entryCount,
      unreadableCount: day.unreadableCount,
    ),
    limits: ref.watch(personalLimitsProvider),
  );
});
