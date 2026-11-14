import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/domain/week.dart';

void main() {
  test('tuần bắt đầu từ thứ Hai, kể cả khi qua tháng và qua năm', () {
    expect(mondayOf(CalendarDate(2026, 11, 11)), CalendarDate(2026, 11, 9));
    expect(mondayOf(CalendarDate(2026, 11, 9)), CalendarDate(2026, 11, 9));
    expect(mondayOf(CalendarDate(2026, 11, 15)), CalendarDate(2026, 11, 9));
    expect(mondayOf(CalendarDate(2027, 1, 2)), CalendarDate(2026, 12, 28));
  });

  test('một tuần có 7 ngày liên tiếp và không sửa được', () {
    final week = weekStartingOn(CalendarDate(2026, 12, 28));

    expect(week.first, CalendarDate(2026, 12, 28));
    expect(week.last, CalendarDate(2027, 1, 3));
    expect(week, hasLength(7));
    expect(week.clear, throwsUnsupportedError);
  });
}
