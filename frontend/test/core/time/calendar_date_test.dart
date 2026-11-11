import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';

void main() {
  test('ngày không tồn tại thì báo lỗi', () {
    expect(() => CalendarDate(2026, 2, 29), throwsArgumentError);
    expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
    expect(CalendarDate(2028, 2, 29).day, 29);
  });

  test('lấy ngày theo múi giờ của chính DateTime, không đổi sang múi giờ khác', () {
    expect(CalendarDate.fromDateTime(DateTime.utc(2026, 11, 10, 22)), CalendarDate(2026, 11, 10));
    expect(CalendarDate.fromDateTime(DateTime(2026, 11, 11, 0, 30)), CalendarDate(2026, 11, 11));
  });

  test('so sánh theo năm, tháng rồi ngày', () {
    expect(CalendarDate(2026, 11, 12).isAfter(CalendarDate(2026, 11, 11)), isTrue);
    expect(CalendarDate(2026, 11, 11).isAfter(CalendarDate(2026, 11, 11)), isFalse);
    expect(CalendarDate(2025, 12, 31).isAfter(CalendarDate(2026, 1, 1)), isFalse);
    expect(CalendarDate(2026, 2, 1).isAfter(CalendarDate(2026, 1, 31)), isTrue);
  });

  test('bằng nhau khi cùng ngày và in ra dạng yyyy-MM-dd', () {
    expect(CalendarDate(2026, 5, 3), CalendarDate(2026, 5, 3));
    expect(CalendarDate(2026, 5, 3).hashCode, CalendarDate(2026, 5, 3).hashCode);
    expect(CalendarDate(2026, 5, 3).toString(), '2026-05-03');
  });
}
