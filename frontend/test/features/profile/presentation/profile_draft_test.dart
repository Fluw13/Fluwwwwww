import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/presentation/profile_draft.dart';

import '../domain/profile_fixture.dart';

ProfileDraft _filled({
  String displayName = '  Lê An ',
  Sex sex = Sex.female,
  BmrFormula? bmrFormulaForOther,
  CalendarDate? birthDate,
  String heightText = '165',
  String weightText = '58,5',
  String targetWeightText = '53.0',
  double? weeklyChangeKg = 0.5,
  String conditionNote = '',
}) {
  return ProfileDraft(
    displayName: displayName,
    sex: sex,
    bmrFormulaForOther: bmrFormulaForOther,
    birthDate: birthDate ?? CalendarDate(1998, 3, 4),
    heightText: heightText,
    weightText: weightText,
    targetWeightText: targetWeightText,
    activityLevel: ActivityLevel.light,
    trainingType: TrainingType.endurance,
    weeklyChangeKg: weeklyChangeKg,
    conditions: const {HealthCondition.gout},
    conditionNote: conditionNote,
    limitsSugar: true,
  );
}

Map<ProfileField, String> _errorsOf(ProfileDraft draft) =>
    (draft.toProfile(today: fixtureToday) as DraftInvalid).errors;

void main() {
  test('bản nháp đủ và đúng thành hồ sơ: đọc số có dấu phẩy, bỏ khoảng trắng, chữ rỗng thành null', () {
    final result = _filled().toProfile(today: fixtureToday);

    expect(
      (result as DraftValid).profile,
      buildProfile(
        displayName: 'Lê An',
        sex: Sex.female,
        birthDate: CalendarDate(1998, 3, 4),
        heightCm: 165,
        weightKg: 58.5,
        targetWeightKg: 53,
        activityLevel: ActivityLevel.light,
        trainingType: TrainingType.endurance,
        weeklyChangeKg: 0.5,
        conditions: {HealthCondition.gout},
        conditionNote: null,
        limitsSugar: true,
      ),
    );
  });

  test('bản nháp trống báo đủ các ô bắt buộc', () {
    expect(_errorsOf(const ProfileDraft()).keys, {
      ProfileField.sex,
      ProfileField.birthDate,
      ProfileField.height,
      ProfileField.weight,
      ProfileField.targetWeight,
      ProfileField.activityLevel,
      ProfileField.trainingType,
    });
  });

  test('số sai dạng báo đúng ô, có ví dụ cách nhập', () {
    final errors = _errorsOf(_filled(heightText: '1m65', weightText: '-58'));

    expect(errors.keys, {ProfileField.height, ProfileField.weight});
    expect(errors[ProfileField.height], contains('58,5'));
  });

  test('số ngoài giới hạn báo theo quy tắc của hồ sơ', () {
    expect(_errorsOf(_filled(heightText: '99')), {ProfileField.height: 'Chiều cao từ 100 đến 250 cm.'});
  });

  test('người lớn muốn giảm cân mà chưa chọn tốc độ thì báo ở ô tốc độ', () {
    expect(_errorsOf(_filled(weeklyChangeKg: null)).keys, {ProfileField.weeklyChange});
  });

  test('giữ cân hoặc dưới 18 tuổi thì bỏ tốc độ cũ, không lưu lại', () {
    final maintain = _filled(targetWeightText: '58.5').toProfile(today: fixtureToday) as DraftValid;
    final teen = _filled(birthDate: CalendarDate(2010, 1, 1)).toProfile(today: fixtureToday) as DraftValid;

    expect(maintain.profile.weeklyChangeKg, isNull);
    expect(teen.profile.weeklyChangeKg, isNull);
    expect(_filled(birthDate: CalendarDate(2010, 1, 1)).needsWeeklyChange(today: fixtureToday), isFalse);
  });

  test('giới tính Khác: người lớn phải chọn công thức BMR; chọn rồi đổi sang Nam thì bỏ công thức', () {
    expect(_errorsOf(_filled(sex: Sex.other)).keys, {ProfileField.bmrFormula});

    final other = _filled(sex: Sex.other, bmrFormulaForOther: BmrFormula.male).toProfile(today: fixtureToday);
    final male = _filled(sex: Sex.male, bmrFormulaForOther: BmrFormula.female).toProfile(today: fixtureToday);

    expect((other as DraftValid).profile.bmrFormulaForOther, BmrFormula.male);
    expect((male as DraftValid).profile.bmrFormulaForOther, isNull);
  });

  test('mở lại hồ sơ đã lưu thì ra bản nháp tạo lại đúng hồ sơ đó', () {
    final profile = buildProfile(
      displayName: 'An',
      heightCm: 172.55,
      conditionNote: 'Hen',
      weeklyChangeKg: 0.25,
      dietary: DietaryPreferences(
        allergies: {Allergen.fish: AllergySeverity.mild},
        allergyNote: 'Kiwi',
        dietStyle: DietStyle.vegan,
        preferences: {FoodPreference.steamedOrBoiled},
      ),
    );

    expect((ProfileDraft.fromProfile(profile).toProfile(today: fixtureToday) as DraftValid).profile, profile);
  });

  test('hai bản nháp cùng nội dung thì bằng nhau, khác một ô thì khác', () {
    expect(_filled(), _filled());
    expect(_filled().hashCode, _filled().hashCode);
    expect(_filled(heightText: '166'), isNot(_filled()));
    expect(_filled(conditionNote: 'Hen'), isNot(_filled()));
  });
}
