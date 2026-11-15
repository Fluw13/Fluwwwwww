import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/reminders/domain/reminder_settings.dart';
import 'package:fluw/features/reminders/domain/reminder_time.dart';

void main() {
  test('giờ nhắc đọc/ghi dạng HH:mm, từ chối giờ sai', () {
    expect(ReminderTime.tryParse('07:05'), const ReminderTime(7, 5));
    expect(const ReminderTime(7, 5).label, '07:05');
    for (final text in ['7:05', '24:00', '12:60', '', '10:00 ', 'ab:cd']) {
      expect(ReminderTime.tryParse(text), isNull, reason: text);
    }
  });

  test('mặc định tắt, giờ 10:00, 17:00, 22:00', () {
    expect(ReminderSettings.defaults.enabled, isFalse);
    expect(ReminderSettings.defaults.times, const [ReminderTime(10, 0), ReminderTime(17, 0), ReminderTime(22, 0)]);
  });

  test('giờ luôn được sắp xếp và không trùng; so sánh theo nội dung', () {
    final settings = ReminderSettings(
      enabled: true,
      times: const [ReminderTime(22, 0), ReminderTime(9, 30), ReminderTime(22, 0)],
    );

    expect(settings.times, const [ReminderTime(9, 30), ReminderTime(22, 0)]);
    expect(settings, ReminderSettings(enabled: true, times: const [ReminderTime(9, 30), ReminderTime(22, 0)]));
    expect(settings.times.clear, throwsUnsupportedError);
  });
}
