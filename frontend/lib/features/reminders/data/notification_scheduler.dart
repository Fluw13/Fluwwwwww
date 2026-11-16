import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/features/reminders/data/local_notification_scheduler.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';

/// The phone's notification system, behind an interface so tests never touch the plugin.
abstract interface class NotificationScheduler {
  /// Asks the user once (Android 13+, iOS); returns whether notifications may be shown.
  Future<bool> requestPermission();

  /// Cancels the meal reminders still pending and schedules [reminders] instead; times already past are skipped.
  /// Calls run one at a time; calls made while another one waits join it, and only the newest plan is applied. Each
  /// call completes with the outcome of the run that applied its plan or a newer one, and fails with the first
  /// reminder that could not be scheduled, after scheduling the rest.
  Future<void> replaceAll(List<PlannedReminder> reminders);
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) => LocalNotificationScheduler());
