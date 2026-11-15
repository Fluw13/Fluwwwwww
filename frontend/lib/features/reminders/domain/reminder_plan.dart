import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/reminders/domain/reminder_message.dart';
import 'package:fluw/features/reminders/domain/reminder_settings.dart';

/// Reminders are scheduled this many days ahead, so they keep coming for a week even if the app is not opened.
const int reminderDaysAhead = 7;

final class PlannedReminder {
  const PlannedReminder({required this.id, required this.at, required this.message});

  /// Stable per day and slot, so scheduling the same plan again replaces instead of duplicating.
  final int id;
  final DateTime at;
  final ReminderMessage message;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder && other.id == id && other.at == at && other.message == message;

  @override
  int get hashCode => Object.hash(id, at, message);
}

/// Today's reminders say what was logged so far; later days get a plain text. Past times are skipped.
List<PlannedReminder> planReminders({
  required ReminderSettings settings,
  required DateTime now,
  required CalendarDate today,
  required DayIntake todayIntake,
  required PersonalLimits limits,
}) {
  if (!settings.enabled) {
    return const [];
  }
  return [
    for (var dayOffset = 0; dayOffset < reminderDaysAhead; dayOffset++)
      for (final (index, time) in settings.times.indexed)
        if (_at(today.addDays(dayOffset), time.hour, time.minute) case final at when at.isAfter(now))
          PlannedReminder(
            id: dayOffset * 10 + index,
            at: at,
            message: reminderMessage(
              moment: ReminderMoment.of(time),
              intake: dayOffset == 0 ? todayIntake : null,
              limits: limits,
            ),
          ),
  ];
}

DateTime _at(CalendarDate day, int hour, int minute) => DateTime(day.year, day.month, day.day, hour, minute);
