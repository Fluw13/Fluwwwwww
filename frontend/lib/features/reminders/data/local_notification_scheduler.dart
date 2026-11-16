import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluw/features/reminders/data/notification_scheduler.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';
import 'package:timezone/timezone.dart' as tz;

/// Local notifications only: nothing is sent to a server. Scheduled as inexact alarms, which need no special
/// permission. Android 12+ delivers them within about an hour of the time (usually sooner); older Android versions and
/// battery saving can delay them more.
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin, DateTime Function()? now})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
      _now = now ?? DateTime.now;

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _now;
  Future<void>? _ready;
  Future<void> _running = Future<void>.value();
  Future<void>? _waiting;
  late List<PlannedReminder> _wanted;

  /// Every reminder is one-shot at an absolute time, which any zone states equally well, so the device's zone and the
  /// zone database are not needed. "UTC" is a name both Android and iOS know. Travel is handled by planning again.
  static final tz.Location _utc = tz.Location('UTC', [tz.minTime], [0], [tz.TimeZone.UTC]);

  /// The plugin rejects times in the past; this covers the time between the check and the call.
  static const Duration _margin = Duration(seconds: 10);

  static NotificationDetails _details(PlannedReminder reminder) => NotificationDetails(
    android: AndroidNotificationDetails(
      'meal_reminders',
      'Nhắc ghi bữa ăn',
      channelDescription: 'Nhắc ghi bữa ăn vào Nhật ký theo giờ bạn chọn',
      // Most phones show every notification in full on the lock screen unless the user changed it, so texts with what
      // was eaten are left off secure lock screens altogether.
      visibility: reminder.message.showsIntake ? NotificationVisibility.secret : NotificationVisibility.private,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  Future<void> _ensureReady() async {
    final attempt = _ready ??= _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    try {
      await attempt;
    } on Object {
      // Tried again on the next call instead of failing for good; a newer attempt already under way is kept.
      if (identical(_ready, attempt)) {
        _ready = null;
      }
      rethrow;
    }
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureReady();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// One plan at a time: turning reminders off while the week is still being scheduled cannot leave part of it behind.
  /// Calls that come in while a run is waiting join it, and it applies the newest of their plans.
  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) {
    _wanted = reminders;
    final waiting = _waiting;
    if (waiting != null) {
      return waiting;
    }
    final run = _running.then((_) {
      _waiting = null;
      return _apply(_wanted);
    });
    _waiting = run;
    _running = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _apply(List<PlannedReminder> reminders) async {
    await _ensureReady();
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (isMealReminderId(pending.id)) {
        await _plugin.cancel(id: pending.id);
      }
    }
    final earliest = _now().add(_margin);
    (Object, StackTrace)? failure;
    for (final reminder in reminders) {
      if (!reminder.at.isAfter(earliest)) {
        continue;
      }
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.message.title,
          body: reminder.message.body,
          scheduledDate: tz.TZDateTime.from(reminder.at, _utc),
          notificationDetails: _details(reminder),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } on Object catch (error, stack) {
        // The other reminders are still scheduled; the caller hears about the first failure.
        failure ??= (error, stack);
      }
    }
    if (failure case (final error, final stack)) {
      Error.throwWithStackTrace(error, stack);
    }
  }
}
