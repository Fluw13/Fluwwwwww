import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/reminders/data/reminder_settings_storage.dart';
import 'package:fluw/features/reminders/domain/reminder_settings.dart';
import 'package:fluw/features/reminders/domain/reminder_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ReminderSettingsStorage> storage(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return ReminderSettingsStorage(await SharedPreferences.getInstance());
  }

  test('chưa lưu gì: mặc định tắt, 10:00, 17:00, 22:00', () async {
    expect((await storage(const {})).load(), ReminderSettings.defaults);
  });

  test('lưu rồi đọc lại đúng', () async {
    final store = await storage(const {});
    final settings = ReminderSettings(enabled: true, times: const [ReminderTime(9, 30), ReminderTime(21, 0)]);

    await store.save(settings);

    expect(store.load(), settings);
  });

  test('giờ hỏng bị bỏ; không còn giờ nào thì về giờ mặc định; kiểu sai thì về mặc định', () async {
    expect(
      (await storage(const {
        ReminderSettingsStorage.timesKey: ['xx', '08:00'],
      })).load().times,
      const [ReminderTime(8, 0)],
    );
    expect(
      (await storage(const {
        ReminderSettingsStorage.timesKey: ['xx'],
      })).load().times,
      ReminderSettings.defaultTimes,
    );
    expect((await storage(const {ReminderSettingsStorage.enabledKey: 'có'})).load(), ReminderSettings.defaults);
  });

  test('kho cài đặt không mở được thì dùng mặc định và không lỗi khi lưu', () async {
    const store = ReminderSettingsStorage(null);

    expect(store.load(), ReminderSettings.defaults);
    await expectLater(store.save(ReminderSettings.defaults), completes);
  });
}
