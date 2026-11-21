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

  group('ngày sinh muộn nhất vẫn đủ 18 tuổi', () {
    test('là ngày này 18 năm trước; muộn hơn một ngày thì chưa đủ 18', () {
      final today = CalendarDate(2026, 11, 11);
      final latest = latestAdultBirthDate(today);

      expect(latest, CalendarDate(2008, 11, 11));
      expect(ageInYears(birthDate: latest, today: today), 18);
      expect(ageInYears(birthDate: latest.addDays(1), today: today), 17);
    });

    test('hôm nay là 29/2 thì là 28/2, vì người sinh 1/3 chưa đủ 18 tuổi', () {
      final today = CalendarDate(2028, 2, 29);
      final latest = latestAdultBirthDate(today);

      expect(latest, CalendarDate(2010, 2, 28));
      expect(ageInYears(birthDate: latest, today: today), 18);
      expect(ageInYears(birthDate: CalendarDate(2010, 3, 1), today: today), 17);
    });
  });
}
