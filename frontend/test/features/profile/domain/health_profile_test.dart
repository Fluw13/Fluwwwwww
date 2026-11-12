import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';

import 'profile_fixture.dart';

void main() {
  test('hai hồ sơ cùng nội dung thì bằng nhau và cùng hashCode, kể cả khi bệnh xếp khác thứ tự', () {
    final first = buildProfile(conditions: {HealthCondition.diabetes, HealthCondition.gout}, conditionNote: 'hen');
    final second = buildProfile(conditions: {HealthCondition.gout, HealthCondition.diabetes}, conditionNote: 'hen');

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('khác bất kỳ trường nào thì không bằng nhau', () {
    final base = buildProfile();
    final changed = [
      base.copyWith(displayName: () => 'An'),
      base.copyWith(sex: Sex.female),
      base.copyWith(bmrFormulaForOther: () => BmrFormula.female),
      base.copyWith(birthDate: CalendarDate(2006, 5, 14)),
      base.copyWith(heightCm: 176),
      base.copyWith(weightKg: 71),
      base.copyWith(targetWeightKg: 66),
      base.copyWith(activityLevel: ActivityLevel.light),
      base.copyWith(trainingType: TrainingType.none),
      base.copyWith(weeklyChangeKg: () => 0.25),
      base.copyWith(conditions: {HealthCondition.hypertension}),
      base.copyWith(conditionNote: () => 'hen'),
      base.copyWith(limitsSugar: true),
    ];

    for (final (index, profile) in changed.indexed) {
      expect(profile, isNot(base), reason: 'trường thứ $index');
    }
  });

  test('copyWith giữ nguyên trường không truyền và xóa được trường để trống', () {
    final base = buildProfile(weeklyChangeKg: 0.5, conditionNote: 'hen', displayName: 'An');

    expect(base.copyWith(), base);
    expect(base.copyWith(weeklyChangeKg: () => null).weeklyChangeKg, isNull);
    expect(base.copyWith(conditionNote: () => null).conditionNote, isNull);
    expect(base.copyWith(displayName: () => null).displayName, isNull);
    expect(base.copyWith(heightCm: 180).weeklyChangeKg, 0.5);
  });

  test('danh sách bệnh không sửa được từ bên ngoài', () {
    final source = {HealthCondition.diabetes};
    final profile = buildProfile(conditions: source);
    source.add(HealthCondition.gout);

    expect(profile.conditions, {HealthCondition.diabetes});
    expect(() => profile.conditions.add(HealthCondition.gout), throwsUnsupportedError);
  });

  test('công thức BMR: Nam/Nữ theo giới tính, Khác theo lựa chọn riêng', () {
    expect(buildProfile(sex: Sex.male, bmrFormulaForOther: BmrFormula.female).bmrFormula, BmrFormula.male);
    expect(buildProfile(sex: Sex.female).bmrFormula, BmrFormula.female);
    expect(buildProfile(sex: Sex.other, bmrFormulaForOther: BmrFormula.female).bmrFormula, BmrFormula.female);
    expect(buildProfile(sex: Sex.other).bmrFormula, isNull);
  });
}
