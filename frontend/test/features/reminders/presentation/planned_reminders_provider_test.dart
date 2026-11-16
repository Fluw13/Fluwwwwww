import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/diary/diary_reader.dart';
import 'package:fluw/core/diary/note_window.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/clock_provider.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/reminders/data/reminder_settings_storage.dart';
import 'package:fluw/features/reminders/presentation/planned_reminders_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Diary implements DiaryReader {
  final StreamController<NoteWindow> controller = StreamController<NoteWindow>.broadcast();

  @override
  Stream<NoteWindow> watchBetween(DateTime from, DateTime to) => controller.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, _Diary)> start({required bool enabled}) async {
    SharedPreferences.setMockInitialValues({ReminderSettingsStorage.enabledKey: enabled});
    final preferences = await SharedPreferences.getInstance();
    final diary = _Diary();
    final container = ProviderContainer(
      overrides: [
        reminderSettingsStorageProvider.overrideWithValue(ReminderSettingsStorage(preferences)),
        diaryReaderProvider.overrideWithValue(diary),
        todayProvider.overrideWithValue(CalendarDate(2026, 11, 11)),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 11, 9)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(plannedRemindersProvider, (_, _) {});
    return (container, diary);
  }

  test('Nhật ký đang tải hoặc lỗi thì không có kế hoạch (giữ lịch cũ), không phải danh sách rỗng', () async {
    final (container, diary) = await start(enabled: true);
    expect(container.read(plannedRemindersProvider), isNull, reason: 'đang tải');

    diary.controller.add(const NoteWindow(entries: [], unreadableCount: 0));
    await pumpEventQueue();
    expect(container.read(plannedRemindersProvider), hasLength(21));

    diary.controller.addError(StateError('Nhật ký hỏng'));
    await pumpEventQueue();
    expect(container.read(plannedRemindersProvider), isNull, reason: 'lỗi');
  });

  test('dòng Nhật ký không đọc được thì nhắc hôm nay nói rõ', () async {
    final (container, diary) = await start(enabled: true);

    diary.controller.add(const NoteWindow(entries: [], unreadableCount: 2));
    await pumpEventQueue();

    expect(
      container.read(plannedRemindersProvider)!.first.message.body,
      'Có 2 món hôm nay không đọc được. Mở Nhật ký để xem lại.',
    );
  });

  test('tắt nhắc nhở thì kế hoạch rỗng ngay, không chờ Nhật ký', () async {
    final (container, _) = await start(enabled: false);

    expect(container.read(plannedRemindersProvider), isEmpty);
  });
}
