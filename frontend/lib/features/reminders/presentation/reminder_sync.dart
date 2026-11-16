import 'dart:async';

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
  /// The plan the phone was last asked for. Starts empty, so with reminders off (the default) nothing runs at launch:
  /// turning them off already cancelled what was scheduled. Null after a failure, so the next plan is sent again.
  List<PlannedReminder>? _sent = const [];
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back in the app: times already past drop out, and after travel the times follow the new time zone.
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(plannedRemindersProvider));
    ref.listenManual<List<PlannedReminder>?>(plannedRemindersProvider, (_, plan) => _send(plan), fireImmediately: true);
  }

  void _send(List<PlannedReminder>? plan) {
    if (plan == null || const ListEquality<PlannedReminder>().equals(_sent, plan)) {
      return;
    }
    _sent = plan;
    unawaited(
      ref.read(notificationSchedulerProvider).replaceAll(plan).catchError((Object error, StackTrace stack) {
        _sent = null;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'fluw reminders',
            context: ErrorDescription('while scheduling meal reminders'),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
