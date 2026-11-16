import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/diary/diary_reader.dart';
import 'package:fluw/core/diary/note_window.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/clock_provider.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/reminders/data/notification_scheduler.dart';
import 'package:fluw/features/reminders/data/reminder_settings_controller.dart';
import 'package:fluw/features/reminders/data/reminder_settings_storage.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';
import 'package:fluw/features/reminders/presentation/reminder_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_notification_scheduler.dart';

class _EmptyDiary implements DiaryReader {
  @override
  Stream<NoteWindow> watchBetween(DateTime from, DateTime to) =>
      Stream.value(const NoteWindow(entries: [], unreadableCount: 0));
}

class _FailingOnce extends FakeNotificationScheduler {
  _FailingOnce({this.onlyEmpty = false});

  /// Fails the first empty plan only (turning reminders off), instead of the first plan.
  final bool onlyEmpty;
  bool failed = false;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await super.replaceAll(reminders);
    if (!failed && (!onlyEmpty || reminders.isEmpty)) {
      failed = true;
      throw StateError('plugin lỗi');
    }
  }
}

void main() {
  late DateTime now;

  Future<FakeNotificationScheduler> pumpSync(
    WidgetTester tester,
    FakeNotificationScheduler scheduler, {
    bool enabled = true,
  }) async {
    SharedPreferences.setMockInitialValues({ReminderSettingsStorage.enabledKey: enabled});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderSettingsStorageProvider.overrideWithValue(ReminderSettingsStorage(preferences)),
          notificationSchedulerProvider.overrideWithValue(scheduler),
          diaryReaderProvider.overrideWithValue(_EmptyDiary()),
          todayProvider.overrideWithValue(CalendarDate(2026, 11, 11)),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const ReminderSync(child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    return scheduler;
  }

  void resume(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  setUp(() => now = DateTime(2026, 11, 11, 9));

  testWidgets('quay lại app sau khi qua giờ nhắc thì hẹn lại, bỏ giờ đã qua', (tester) async {
    final scheduler = await pumpSync(tester, FakeNotificationScheduler());
    expect(scheduler.current, hasLength(21));

    now = DateTime(2026, 11, 11, 10, 30);
    resume(tester);
    await tester.pumpAndSettle();

    expect(scheduler.scheduled, hasLength(2));
    expect(scheduler.current!.first.at, DateTime(2026, 11, 11, 17));
  });

  testWidgets('mở app khi đang tắt nhắc thì vẫn gửi kế hoạch rỗng một lần, để hủy nhắc còn sót lần trước', (
    tester,
  ) async {
    final scheduler = await pumpSync(tester, FakeNotificationScheduler(), enabled: false);

    expect(scheduler.scheduled, [isEmpty]);
  });

  testWidgets('tắt nhắc mà hủy lỗi thì quay lại app sẽ hủy lại', (tester) async {
    final scheduler = await pumpSync(tester, _FailingOnce(onlyEmpty: true));
    expect(scheduler.current, hasLength(21));

    final container = ProviderScope.containerOf(tester.element(find.byType(SizedBox)));
    final settings = container.read(reminderSettingsProvider);
    await tester.runAsync(
      () => container.read(reminderSettingsProvider.notifier).update(settings.copyWith(enabled: false)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<StateError>());

    resume(tester);
    await tester.pumpAndSettle();

    expect(scheduler.scheduled.map((plan) => plan.length), [21, 0, 0]);
  });

  testWidgets('hẹn lỗi thì báo lỗi và lần sau gửi lại kế hoạch, kể cả khi kế hoạch không đổi', (tester) async {
    final scheduler = await pumpSync(tester, _FailingOnce());
    expect(tester.takeException(), isA<StateError>());

    resume(tester);
    await tester.pumpAndSettle();

    expect(scheduler.scheduled, hasLength(2));
    expect(scheduler.scheduled.last, scheduler.scheduled.first);
  });
}
