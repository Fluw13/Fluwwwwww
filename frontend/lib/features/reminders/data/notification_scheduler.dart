import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/features/reminders/data/local_notification_scheduler.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';

/// The phone's notification system, behind an interface so tests never touch the plugin.
abstract interface class NotificationScheduler {
  /// Asks the user once (Android 13+, iOS); returns whether notifications may be shown.
  Future<bool> requestPermission();

  /// Cancels every scheduled reminder and schedules [reminders] instead.
  Future<void> replaceAll(List<PlannedReminder> reminders);
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) => LocalNotificationScheduler());
