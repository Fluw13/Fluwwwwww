import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
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
  bool? isPregnantOrBreastfeeding = false,
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
    isPregnantOrBreastfeeding: isPregnantOrBreastfeeding,
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
    final minor = _filled(birthDate: CalendarDate(2010, 1, 1)).toProfile(today: fixtureToday) as DraftValid;

    expect(maintain.profile.weeklyChangeKg, isNull);
    expect(minor.profile.weeklyChangeKg, isNull);
    expect(_filled(birthDate: CalendarDate(2010, 1, 1)).needsWeeklyChange(today: fixtureToday), isFalse);
  });

  test('giới tính Khác: người lớn phải chọn công thức BMR; chọn rồi đổi sang Nam thì bỏ công thức', () {
    expect(_errorsOf(_filled(sex: Sex.other)).keys, {ProfileField.bmrFormula});

    final other = _filled(sex: Sex.other, bmrFormulaForOther: BmrFormula.male).toProfile(today: fixtureToday);
    final male = _filled(sex: Sex.male, bmrFormulaForOther: BmrFormula.female).toProfile(today: fixtureToday);

    expect((other as DraftValid).profile.bmrFormulaForOther, BmrFormula.male);
    expect((male as DraftValid).profile.bmrFormulaForOther, isNull);
  });

  group('mang thai hoặc cho con bú', () {
    test('chỉ hỏi khi theo công thức Nữ', () {
      expect(const ProfileDraft(sex: Sex.female).asksPregnancy, isTrue);
      expect(const ProfileDraft(sex: Sex.other, bmrFormulaForOther: BmrFormula.female).asksPregnancy, isTrue);
      expect(const ProfileDraft(sex: Sex.other, bmrFormulaForOther: BmrFormula.male).asksPregnancy, isFalse);
      expect(const ProfileDraft(sex: Sex.other).asksPregnancy, isFalse);
      expect(const ProfileDraft(sex: Sex.male).asksPregnancy, isFalse);
      expect(const ProfileDraft().asksPregnancy, isFalse);
    });

    test('nữ chưa trả lời thì báo ở ô câu hỏi', () {
      expect(_errorsOf(_filled(isPregnantOrBreastfeeding: null)), {
        ProfileField.pregnancy: 'Cho biết bạn có đang mang thai hoặc cho con bú không.',
      });
    });

    test('trả lời Có thì không hỏi tốc độ và bỏ tốc độ cũ', () {
      final pregnant = _filled(isPregnantOrBreastfeeding: true);

      expect(pregnant.needsWeeklyChange(today: fixtureToday), isFalse);
      final profile = (pregnant.toProfile(today: fixtureToday) as DraftValid).profile;
      expect(profile.isPregnantOrBreastfeeding, isTrue);
      expect(profile.weeklyChangeKg, isNull);
    });

    test('câu trả lời cũ không làm người theo công thức Nam mất ô tốc độ', () {
      expect(_filled(sex: Sex.male, isPregnantOrBreastfeeding: true).needsWeeklyChange(today: fixtureToday), isTrue);
    });
  });

  test('giảm cân xuống dưới BMI 18,5 hoặc giảm khi đang thiếu cân thì báo ở ô cân nặng mong muốn', () {
    // 165 cm: BMI 18.5 là 50,37 kg.
    expect(_errorsOf(_filled(targetWeightText: '50')).keys, {ProfileField.targetWeight});
    expect(
      _errorsOf(_filled(targetWeightText: '50'))[ProfileField.targetWeight],
      startsWith('Cân nặng mong muốn cho BMI dưới 18.5'),
    );
    expect(
      _errorsOf(_filled(weightText: '50', targetWeightText: '48'))[ProfileField.targetWeight],
      startsWith('Bạn đang thiếu cân'),
    );
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
    final pregnant = buildProfile(sex: Sex.female, isPregnantOrBreastfeeding: true, weeklyChangeKg: null);
    expect((ProfileDraft.fromProfile(pregnant).toProfile(today: fixtureToday) as DraftValid).profile, pregnant);
  });

  test('hai bản nháp cùng nội dung thì bằng nhau, khác một ô thì khác', () {
    expect(_filled(), _filled());
    expect(_filled().hashCode, _filled().hashCode);
    expect(_filled(heightText: '166'), isNot(_filled()));
    expect(_filled(conditionNote: 'Hen'), isNot(_filled()));
    expect(_filled(isPregnantOrBreastfeeding: true), isNot(_filled()));
  });

  group('BMI xem trước', () {
    test('người lớn, không mang thai, số trong giới hạn: BMI theo số đang nhập (58,5 kg, 165 cm → 21.4)', () {
      final bmi = _filled().previewBmi(today: fixtureToday)!;
      expect(bmi.displayValue, 21.4);
      expect(bmi.category, BmiCategory.normal);
    });

    test('chưa trả lời câu hỏi mang thai hoặc đang mang thai: không có BMI', () {
      expect(_filled(isPregnantOrBreastfeeding: null).previewBmi(today: fixtureToday), isNull);
      expect(_filled(isPregnantOrBreastfeeding: true).previewBmi(today: fixtureToday), isNull);
    });

    test('Khác theo công thức Nam không bị hỏi mang thai nên vẫn có BMI', () {
      final draft = _filled(sex: Sex.other, bmrFormulaForOther: BmrFormula.male, isPregnantOrBreastfeeding: null);
      expect(draft.previewBmi(today: fixtureToday), isNotNull);
    });

    test('dưới 18 tuổi hoặc trên 100 tuổi: không có BMI', () {
      expect(_filled(birthDate: CalendarDate(2008, 11, 12)).previewBmi(today: fixtureToday), isNull);
      expect(_filled(birthDate: CalendarDate(2008, 11, 11)).previewBmi(today: fixtureToday), isNotNull);
      expect(_filled(birthDate: CalendarDate(1925, 11, 11)).previewBmi(today: fixtureToday), isNull);
    });

    test('thiếu số hoặc ngoài giới hạn chiều cao, cân nặng: không có BMI', () {
      expect(_filled(heightText: '').previewBmi(today: fixtureToday), isNull);
      expect(_filled(heightText: '99').previewBmi(today: fixtureToday), isNull);
      expect(_filled(heightText: '251').previewBmi(today: fixtureToday), isNull);
      expect(_filled(weightText: '19,9').previewBmi(today: fixtureToday), isNull);
      expect(_filled(weightText: '300.1').previewBmi(today: fixtureToday), isNull);
      expect(_filled(heightText: '100', weightText: '300').previewBmi(today: fixtureToday), isNotNull);
    });
  });
}
