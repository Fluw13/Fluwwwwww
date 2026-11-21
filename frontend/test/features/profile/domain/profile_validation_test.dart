import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

import 'profile_fixture.dart';

void main() {
  Set<ProfileIssue> issuesOf({
    CalendarDate? birthDate,
    double heightCm = 175,
    double weightKg = 70,
    double targetWeightKg = 65,
    double? weeklyChangeKg = 0.5,
  }) {
    final profile = buildProfile(
      birthDate: birthDate,
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: targetWeightKg,
      weeklyChangeKg: weeklyChangeKg,
    );
    return validateProfile(profile, today: fixtureToday);
  }

  test('hồ sơ hợp lệ thì không có lỗi', () {
    expect(issuesOf(), isEmpty);
  });

  test('ngày sinh ở tương lai là lỗi; sinh hôm nay thì không', () {
    expect(issuesOf(birthDate: CalendarDate(2026, 11, 12)), {ProfileIssue.birthDateInFuture});
    expect(issuesOf(birthDate: CalendarDate(2026, 11, 11)), isEmpty);
  });

  test('trên 100 tuổi là lỗi; còn 1 ngày nữa mới 101 tuổi thì không', () {
    expect(issuesOf(birthDate: CalendarDate(1925, 11, 12)), isEmpty);
    expect(issuesOf(birthDate: CalendarDate(1925, 11, 11)), {ProfileIssue.birthDateTooOld});
  });

  test('chiều cao trong khoảng 100–250 cm, tính cả hai đầu', () {
    expect(issuesOf(heightCm: 100), isEmpty);
    expect(issuesOf(heightCm: 250, weightKg: 160, targetWeightKg: 150), isEmpty);
    expect(issuesOf(heightCm: 99.9), {ProfileIssue.heightOutOfRange});
    expect(issuesOf(heightCm: 250.1), {ProfileIssue.heightOutOfRange});
  });

  test('cân nặng hiện tại và mong muốn trong khoảng 20–300 kg', () {
    expect(issuesOf(weightKg: 19.9), {ProfileIssue.weightOutOfRange});
    expect(issuesOf(weightKg: 300.1), {ProfileIssue.weightOutOfRange});
    expect(issuesOf(targetWeightKg: 19.9), {ProfileIssue.targetWeightOutOfRange});
    expect(issuesOf(targetWeightKg: 301), {ProfileIssue.targetWeightOutOfRange});
  });

  test('cân nặng NaN là lỗi chứ không làm crash', () {
    expect(issuesOf(weightKg: double.nan), {ProfileIssue.weightOutOfRange});
  });

  test('người lớn muốn tăng/giảm cân thì phải có tốc độ đổi cân', () {
    expect(issuesOf(weeklyChangeKg: null), {ProfileIssue.weeklyChangeMissing});
  });

  test('giữ cân hoặc dưới 18 tuổi thì không cần tốc độ đổi cân', () {
    expect(issuesOf(targetWeightKg: 70, weeklyChangeKg: null), isEmpty);
    expect(issuesOf(birthDate: CalendarDate(2010, 1, 1), weeklyChangeKg: null), isEmpty);
  });

  test('tốc độ đổi cân đã nhập thì phải lớn hơn 0 và không quá 0,5 kg/tuần', () {
    expect(issuesOf(weeklyChangeKg: 0), {ProfileIssue.weeklyChangeOutOfRange});
    expect(issuesOf(weeklyChangeKg: -0.5), {ProfileIssue.weeklyChangeOutOfRange});
    expect(issuesOf(weeklyChangeKg: 0.6), {ProfileIssue.weeklyChangeOutOfRange});
  });

  test('nhiều lỗi thì báo đủ tất cả', () {
    expect(issuesOf(heightCm: 50, weightKg: 500), {ProfileIssue.heightOutOfRange, ProfileIssue.weightOutOfRange});
  });

  test('giới tính Khác: người lớn phải chọn công thức BMR, dưới 18 tuổi thì không cần', () {
    expect(validateProfile(buildProfile(sex: Sex.other), today: fixtureToday), {ProfileIssue.bmrFormulaMissing});
    expect(
      validateProfile(
        buildProfile(sex: Sex.other, bmrFormulaForOther: BmrFormula.male),
        today: fixtureToday,
      ),
      isEmpty,
    );
    expect(
      validateProfile(
        buildProfile(sex: Sex.other, birthDate: CalendarDate(2010, 1, 1), weeklyChangeKg: null),
        today: fixtureToday,
      ),
      isEmpty,
    );
  });

  group('chặn giảm cân xuống thiếu cân (BMI dưới 18,5 thang châu Á, cắt xuống 0,1)', () {
    // 175 cm: BMI 18.5 là 56,65625 kg.
    test('cân nặng mong muốn 56,6 kg (BMI 18,4) là lỗi; 56,7 kg (BMI 18,5) thì được', () {
      expect(issuesOf(targetWeightKg: 56.6), {ProfileIssue.targetBmiTooLow});
      expect(issuesOf(targetWeightKg: 56.7), isEmpty);
    });

    test('đang thiếu cân thì không được giảm cân, chỉ báo một lỗi', () {
      expect(issuesOf(weightKg: 56, targetWeightKg: 54), {ProfileIssue.loseWhenUnderweight});
    });

    test('đang thiếu cân vẫn được tăng cân hoặc giữ cân, kể cả mục tiêu chưa tới BMI 18,5', () {
      expect(issuesOf(weightKg: 50, targetWeightKg: 55), isEmpty);
      expect(issuesOf(weightKg: 56, targetWeightKg: 56, weeklyChangeKg: null), isEmpty);
    });

    test('đã giảm tới mục tiêu thì chuyển sang giữ cân, không báo lỗi', () {
      final reached = buildProfile(weightKg: 56, targetWeightKg: 57, plannedGoal: WeightGoal.lose);

      expect(validateProfile(reached, today: fixtureToday), isEmpty);
    });

    test('chiều cao sai thì chưa xét BMI', () {
      expect(issuesOf(heightCm: 50, targetWeightKg: 21), {ProfileIssue.heightOutOfRange});
    });
  });

  group('câu hỏi mang thai hoặc cho con bú', () {
    Set<ProfileIssue> issuesFor({required Sex sex, BmrFormula? formula, bool? answer, CalendarDate? birthDate}) {
      return validateProfile(
        buildProfile(
          sex: sex,
          bmrFormulaForOther: formula,
          isPregnantOrBreastfeeding: answer,
          birthDate: birthDate,
          weeklyChangeKg: birthDate == null ? 0.5 : null,
        ),
        today: fixtureToday,
      );
    }

    test('người lớn theo công thức Nữ phải trả lời', () {
      expect(issuesFor(sex: Sex.female), {ProfileIssue.pregnancyAnswerMissing});
      expect(issuesFor(sex: Sex.other, formula: BmrFormula.female), {ProfileIssue.pregnancyAnswerMissing});
      expect(issuesFor(sex: Sex.female, answer: false), isEmpty);
    });

    test('công thức Nam hoặc dưới 18 tuổi thì không hỏi', () {
      expect(issuesFor(sex: Sex.male), isEmpty);
      expect(issuesFor(sex: Sex.other, formula: BmrFormula.male), isEmpty);
      expect(issuesFor(sex: Sex.female, birthDate: CalendarDate(2010, 1, 1)), isEmpty);
    });

    test('đang mang thai hoặc cho con bú thì không cần tốc độ đổi cân', () {
      final pregnant = buildProfile(sex: Sex.female, isPregnantOrBreastfeeding: true, weeklyChangeKg: null);

      expect(validateProfile(pregnant, today: fixtureToday), isEmpty);
    });
  });
}
