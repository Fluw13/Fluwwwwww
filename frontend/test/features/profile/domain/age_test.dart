import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/age.dart';

void main() {
  final birthDate = DateTime(2006, 5, 13);

  test('đủ tuổi đúng vào ngày sinh nhật', () {
    expect(ageInYears(birthDate: birthDate, today: DateTime(2026, 5, 13)), 20);
  });

  test('trước ngày sinh nhật một ngày thì chưa thêm tuổi', () {
    expect(ageInYears(birthDate: birthDate, today: DateTime(2026, 5, 12)), 19);
  });

  test('sau sinh nhật trong năm vẫn giữ tuổi đó', () {
    expect(ageInYears(birthDate: birthDate, today: DateTime(2026, 11, 11, 23, 59)), 20);
  });

  test('sinh ngày 29/2: năm không nhuận thì tính thêm tuổi từ 1/3', () {
    final leapDay = DateTime(2008, 2, 29);

    expect(ageInYears(birthDate: leapDay, today: DateTime(2026, 2, 28)), 17);
    expect(ageInYears(birthDate: leapDay, today: DateTime(2026, 3, 1)), 18);
  });
}
