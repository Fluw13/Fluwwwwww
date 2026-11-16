import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/reminders/data/local_notification_scheduler.dart';
import 'package:fluw/features/reminders/domain/reminder_message.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';
import 'package:timezone/timezone.dart' as tz;

/// Acts like the plugin: every call takes a platform round trip, and past times are rejected as the plugin does.
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final Map<int, tz.TZDateTime> pending = {};
  final Map<int, NotificationDetails> details = {};
  int initializeCalls = 0;
  bool failInitialize = false;
  Set<int> failingIds = {};

  Future<T> _roundTrip<T>(T Function() action) => Future<T>.delayed(const Duration(milliseconds: 1), action);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final named = invocation.namedArguments;
    switch (invocation.memberName) {
      case #initialize:
        initializeCalls++;
        return failInitialize
            ? Future<bool?>.error(PlatformException(code: 'invalid_icon'))
            : _roundTrip<bool?>(() => true);
      case #pendingNotificationRequests:
        return _roundTrip(() => [for (final id in pending.keys) PendingNotificationRequest(id, null, null, null)]);
      case #cancel:
        return _roundTrip(() => pending.remove(named[#id]! as int));
      case #zonedSchedule:
        final id = named[#id]! as int;
        final date = named[#scheduledDate]! as tz.TZDateTime;
        if (failingIds.contains(id) || date.isBefore(DateTime.now())) {
          return Future<void>.error(ArgumentError.value(date, 'scheduledDate', 'Must be a date in the future'));
        }
        return _roundTrip(() {
          pending[id] = date;
          details[id] = named[#notificationDetails]! as NotificationDetails;
        });
    }
    return super.noSuchMethod(invocation);
  }
}

PlannedReminder _reminder(int id, DateTime at, {bool showsIntake = false}) => PlannedReminder(
  id: id,
  at: at,
  message: ReminderMessage(title: 'Fluw', body: 'Ghi bữa', showsIntake: showsIntake),
);

List<PlannedReminder> _week(DateTime from) => [
  for (var i = 0; i < 21; i++) _reminder(i, from.add(Duration(hours: 1 + 8 * i))),
];

void main() {
  test('tắt nhắc nhở ngay khi đang hẹn dở tuần trước thì không còn nhắc nào', () async {
    final plugin = _FakePlugin();
    final scheduler = LocalNotificationScheduler(plugin: plugin);

    final enabling = scheduler.replaceAll(_week(DateTime.now()));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final disabling = scheduler.replaceAll(const []);
    await Future.wait([enabling, disabling]);

    expect(plugin.pending, isEmpty);
  });

  test('nhiều kế hoạch tới cùng lúc thì chỉ áp kế hoạch mới nhất', () async {
    final plugin = _FakePlugin();
    final scheduler = LocalNotificationScheduler(plugin: plugin);
    final now = DateTime.now();

    await Future.wait([
      scheduler.replaceAll(_week(now)),
      scheduler.replaceAll([_reminder(1, now.add(const Duration(hours: 2)))]),
      scheduler.replaceAll([_reminder(2, now.add(const Duration(hours: 3)))]),
    ]);

    expect(plugin.pending.keys, [2]);
  });

  test('giờ chỉ còn vài giây khi tới lượt hẹn thì bỏ qua, không làm hỏng cả lượt', () async {
    final plugin = _FakePlugin();
    final now = DateTime.now();
    final scheduler = LocalNotificationScheduler(plugin: plugin, now: () => now);

    await scheduler.replaceAll([
      _reminder(0, now.add(const Duration(seconds: 5))),
      _reminder(1, now.add(const Duration(hours: 1))),
    ]);

    expect(plugin.pending.keys, [1]);
  });

  test('một nhắc lỗi không làm mất các nhắc còn lại; lỗi đầu tiên vẫn báo cho nơi gọi', () async {
    final plugin = _FakePlugin()..failingIds = {1};
    final scheduler = LocalNotificationScheduler(plugin: plugin);

    await expectLater(
      scheduler.replaceAll([for (var i = 0; i < 4; i++) _reminder(i, DateTime.now().add(Duration(hours: i + 1)))]),
      throwsArgumentError,
    );

    expect(plugin.pending.keys, unorderedEquals([0, 2, 3]));
  });

  test('chỉ hủy nhắc bữa ăn đang chờ, không đụng thông báo khác (nhắc uống nước)', () async {
    final plugin = _FakePlugin();
    final scheduler = LocalNotificationScheduler(plugin: plugin);
    final later = tz.TZDateTime.from(DateTime.now().add(const Duration(days: 1)), tz.UTC);
    plugin.pending.addAll({5: later, mealReminderIdEnd: later});

    await scheduler.replaceAll(const []);

    expect(plugin.pending.keys, [mealReminderIdEnd]);
  });

  test('khởi động plugin lỗi thì lần sau thử lại, không hỏng mãi', () async {
    final plugin = _FakePlugin()..failInitialize = true;
    final scheduler = LocalNotificationScheduler(plugin: plugin);

    await expectLater(scheduler.replaceAll(const []), throwsA(isA<PlatformException>()));
    plugin.failInitialize = false;
    await scheduler.replaceAll([_reminder(0, DateTime.now().add(const Duration(hours: 1)))]);

    expect(plugin.initializeCalls, 2);
    expect(plugin.pending.keys, [0]);
  });

  test('giữ đúng thời điểm; nhắc có số liệu ăn uống không hiện trên màn khóa, nhắc chung thì hiện', () async {
    final plugin = _FakePlugin();
    final scheduler = LocalNotificationScheduler(plugin: plugin);
    final at = DateTime.now().add(const Duration(hours: 5));

    await scheduler.replaceAll([_reminder(0, at, showsIntake: true), _reminder(1, at)]);

    expect(plugin.pending[0]!.isAtSameMomentAs(at), isTrue);
    final personal = plugin.details[0]!.android!;
    expect(personal.channelId, 'meal_reminders');
    expect(personal.visibility, NotificationVisibility.secret);
    expect(plugin.details[1]!.android!.visibility, NotificationVisibility.private);
  });
}
