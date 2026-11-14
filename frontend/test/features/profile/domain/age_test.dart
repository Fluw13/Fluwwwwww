import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/age.dart';

void main() {
  final birthDate = CalendarDate(2006, 3, 8);

  test('đủ tuổi đúng vào ngày sinh nhật', () {
    expect(ageInYears(birthDate: birthDate, today: CalendarDate(2026, 3, 8)), 20);
  });

  test('trước ngày sinh nhật một ngày thì chưa thêm tuổi', () {
    expect(ageInYears(birthDate: birthDate, today: CalendarDate(2026, 3, 7)), 19);
  });

  test('sau sinh nhật trong năm vẫn giữ tuổi đó', () {
    expect(ageInYears(birthDate: birthDate, today: CalendarDate(2026, 11, 11)), 20);
  });

  test('sinh vào tháng sau tháng hiện tại thì chưa thêm tuổi', () {
    expect(ageInYears(birthDate: CalendarDate(2008, 12, 1), today: CalendarDate(2026, 11, 11)), 17);
  });

  test('sinh ngày 29/2: năm không nhuận thì tính thêm tuổi từ 1/3', () {
    final leapDay = CalendarDate(2008, 2, 29);

    expect(ageInYears(birthDate: leapDay, today: CalendarDate(2026, 2, 28)), 17);
    expect(ageInYears(birthDate: leapDay, today: CalendarDate(2026, 3, 1)), 18);
  });
}
