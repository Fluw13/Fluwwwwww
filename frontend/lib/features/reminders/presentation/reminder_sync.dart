import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/features/reminders/data/notification_scheduler.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';
import 'package:fluw/features/reminders/presentation/planned_reminders_provider.dart';

/// Keeps the phone's scheduled reminders in step with the settings, the profile and today's diary, so each text says
/// what was logged so far. Only reschedules when the plan really changed.
class ReminderSync extends ConsumerStatefulWidget {
  const ReminderSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends ConsumerState<ReminderSync> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<List<PlannedReminder>?>(plannedRemindersProvider, (previous, next) {
      if (next != null && !const ListEquality<PlannedReminder>().equals(previous, next)) {
        ref.read(notificationSchedulerProvider).replaceAll(next).ignore();
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
