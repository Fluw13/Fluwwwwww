import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';

import 'profile_fixture.dart';

void main() {
  test('hồ sơ hợp lệ thì không có lỗi', () {
    expect(validateProfile(buildProfile(), today: fixtureToday), isEmpty);
  });

  test('ngày sinh ở tương lai là lỗi; sinh hôm nay thì không', () {
    expect(validateProfile(buildProfile(birthDate: DateTime(2026, 11, 12)), today: fixtureToday), {
      ProfileIssue.birthDateInFuture,
    });
    expect(validateProfile(buildProfile(birthDate: DateTime(2026, 11, 11, 20)), today: fixtureToday), isEmpty);
  });

  test('chiều cao trong khoảng 100–250 cm, tính cả hai đầu', () {
    expect(validateProfile(buildProfile(heightCm: 100), today: fixtureToday), isEmpty);
    expect(validateProfile(buildProfile(heightCm: 250), today: fixtureToday), isEmpty);
    expect(validateProfile(buildProfile(heightCm: 99.9), today: fixtureToday), {ProfileIssue.heightOutOfRange});
    expect(validateProfile(buildProfile(heightCm: 250.1), today: fixtureToday), {ProfileIssue.heightOutOfRange});
  });

  test('cân nặng hiện tại và mong muốn trong khoảng 20–300 kg', () {
    expect(validateProfile(buildProfile(weightKg: 19.9), today: fixtureToday), {ProfileIssue.weightOutOfRange});
    expect(validateProfile(buildProfile(targetWeightKg: 301), today: fixtureToday), {
      ProfileIssue.targetWeightOutOfRange,
    });
  });

  test('tốc độ thay đổi cân phải lớn hơn 0 và không quá 0,5 kg/tuần', () {
    expect(validateProfile(buildProfile(weeklyChangeKg: 0), today: fixtureToday), {
      ProfileIssue.weeklyChangeOutOfRange,
    });
    expect(validateProfile(buildProfile(weeklyChangeKg: 0.6), today: fixtureToday), {
      ProfileIssue.weeklyChangeOutOfRange,
    });
  });

  test('nhiều lỗi thì báo đủ tất cả', () {
    final issues = validateProfile(buildProfile(heightCm: 50, weightKg: 500), today: fixtureToday);

    expect(issues, {ProfileIssue.heightOutOfRange, ProfileIssue.weightOutOfRange});
  });
}
