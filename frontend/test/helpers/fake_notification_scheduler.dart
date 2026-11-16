import 'package:fluw/features/reminders/data/notification_scheduler.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';

/// Records what the app asks of the phone's notification system; the permission answer is set per test.
class FakeNotificationScheduler implements NotificationScheduler {
  bool grantPermission = true;
  int permissionRequests = 0;
  final List<List<PlannedReminder>> scheduled = [];

  List<PlannedReminder>? get current => scheduled.lastOrNull;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grantPermission;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async => scheduled.add(List.unmodifiable(reminders));
}
