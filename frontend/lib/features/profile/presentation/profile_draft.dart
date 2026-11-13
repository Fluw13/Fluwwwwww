import 'package:collection/collection.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

enum ProfileField {
  sex,
  bmrFormula,
  birthDate,
  height,
  weight,
  targetWeight,
  weeklyChange,
  activityLevel,
  trainingType,
}

/// The weekly speeds offered in the form; both stay within the approved 0.5 kg/week limit.
const List<double> weeklyChangeOptionsKg = [0.25, 0.5];

/// What the user has typed so far. Turns into a [HealthProfile] only when every field is filled in and valid.
final class ProfileDraft {
  const ProfileDraft({
    this.displayName = '',
    this.sex,
    this.bmrFormulaForOther,
    this.birthDate,
    this.heightText = '',
    this.weightText = '',
    this.targetWeightText = '',
    this.activityLevel,
    this.trainingType,
    this.weeklyChangeKg,
    this.conditions = const {},
    this.conditionNote = '',
    this.limitsSugar = false,
    this.allergies = const {},
    this.allergyNote = '',
    this.dietStyle = DietStyle.regular,
    this.preferences = const {},
  });

  factory ProfileDraft.fromProfile(HealthProfile profile) {
    return ProfileDraft(
      displayName: profile.displayName ?? '',
      sex: profile.sex,
      bmrFormulaForOther: profile.bmrFormulaForOther,
      birthDate: profile.birthDate,
      // Two decimals match what the form accepts, so opening and saving again never changes a stored number.
      heightText: formatDecimal(profile.heightCm, maxFractionDigits: 2),
      weightText: formatDecimal(profile.weightKg, maxFractionDigits: 2),
      targetWeightText: formatDecimal(profile.targetWeightKg, maxFractionDigits: 2),
      activityLevel: profile.activityLevel,
      trainingType: profile.trainingType,
      weeklyChangeKg: profile.weeklyChangeKg,
      conditions: profile.conditions,
      conditionNote: profile.conditionNote ?? '',
      limitsSugar: profile.limitsSugar,
      allergies: profile.dietary.allergies,
      allergyNote: profile.dietary.allergyNote ?? '',
      dietStyle: profile.dietary.dietStyle,
      preferences: profile.dietary.preferences,
    );
  }

  final String displayName;
  final Sex? sex;
  final BmrFormula? bmrFormulaForOther;
  final CalendarDate? birthDate;
  final String heightText;
  final String weightText;
  final String targetWeightText;
  final ActivityLevel? activityLevel;
  final TrainingType? trainingType;
  final double? weeklyChangeKg;
  final Set<HealthCondition> conditions;
  final String conditionNote;
  final bool limitsSugar;
  final Map<Allergen, AllergySeverity> allergies;
  final String allergyNote;
  final DietStyle dietStyle;
  final Set<FoodPreference> preferences;

  /// The goal implied by the two weights, once both are valid numbers.
  WeightGoal? get goal {
    final weightKg = parseDecimal(weightText);
    final targetWeightKg = parseDecimal(targetWeightText);
    if (weightKg == null || targetWeightKg == null) {
      return null;
    }
    return WeightGoal.fromWeights(currentKg: weightKg, targetKg: targetWeightKg);
  }

  /// Adults who want to change weight pick a weekly speed; teens get no calorie target, so they never need one.
  bool needsWeeklyChange({required CalendarDate today}) {
    final birthDate = this.birthDate;
    final goal = this.goal;
    return birthDate != null &&
        ageInYears(birthDate: birthDate, today: today) >= adultAgeYears &&
        goal != null &&
        goal != WeightGoal.maintain;
  }

  @override
  bool operator ==(Object other) =>
      other is ProfileDraft &&
      other.displayName == displayName &&
      other.sex == sex &&
      other.bmrFormulaForOther == bmrFormulaForOther &&
      other.birthDate == birthDate &&
      other.heightText == heightText &&
      other.weightText == weightText &&
      other.targetWeightText == targetWeightText &&
      other.activityLevel == activityLevel &&
      other.trainingType == trainingType &&
      other.weeklyChangeKg == weeklyChangeKg &&
      const SetEquality<HealthCondition>().equals(other.conditions, conditions) &&
      other.conditionNote == conditionNote &&
      other.limitsSugar == limitsSugar &&
      const MapEquality<Allergen, AllergySeverity>().equals(other.allergies, allergies) &&
      other.allergyNote == allergyNote &&
      other.dietStyle == dietStyle &&
      const SetEquality<FoodPreference>().equals(other.preferences, preferences);

  @override
  int get hashCode => Object.hash(
    displayName,
    sex,
    bmrFormulaForOther,
    birthDate,
    heightText,
    weightText,
    targetWeightText,
    activityLevel,
    trainingType,
    weeklyChangeKg,
    Object.hashAllUnordered(conditions),
    conditionNote,
    limitsSugar,
    Object.hashAllUnordered(allergies.entries.map((entry) => Object.hash(entry.key, entry.value))),
    allergyNote,
    dietStyle,
    Object.hashAllUnordered(preferences),
  );

  DraftResult toProfile({required CalendarDate today}) {
    final heightCm = parseDecimal(heightText);
    final weightKg = parseDecimal(weightText);
    final targetWeightKg = parseDecimal(targetWeightText);
    final sex = this.sex;
    final birthDate = this.birthDate;
    final activityLevel = this.activityLevel;
    final trainingType = this.trainingType;

    final errors = <ProfileField, String>{
      if (sex == null) ProfileField.sex: 'Chọn giới tính.',
      if (birthDate == null) ProfileField.birthDate: 'Chọn ngày sinh.',
      ProfileField.height: ?_numberError(heightText, heightCm, 'chiều cao'),
      ProfileField.weight: ?_numberError(weightText, weightKg, 'cân nặng'),
      ProfileField.targetWeight: ?_numberError(targetWeightText, targetWeightKg, 'cân nặng mong muốn'),
      if (activityLevel == null) ProfileField.activityLevel: 'Chọn mức vận động.',
      if (trainingType == null) ProfileField.trainingType: 'Chọn hình thức tập.',
    };
    if (sex == null ||
        birthDate == null ||
        heightCm == null ||
        weightKg == null ||
        targetWeightKg == null ||
        activityLevel == null ||
        trainingType == null) {
      return DraftInvalid(errors);
    }

    final profile = HealthProfile(
      displayName: _textOrNull(displayName),
      sex: sex,
      bmrFormulaForOther: sex == Sex.other ? bmrFormulaForOther : null,
      birthDate: birthDate,
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: targetWeightKg,
      activityLevel: activityLevel,
      trainingType: trainingType,
      // A speed left over from an earlier goal is dropped so it never comes back unnoticed.
      weeklyChangeKg: needsWeeklyChange(today: today) ? weeklyChangeKg : null,
      conditions: conditions,
      conditionNote: _textOrNull(conditionNote),
      limitsSugar: limitsSugar,
      dietary: DietaryPreferences(
        allergies: allergies,
        allergyNote: _textOrNull(allergyNote),
        dietStyle: dietStyle,
        preferences: preferences,
      ),
    );
    final issues = validateProfile(profile, today: today);
    if (issues.isNotEmpty) {
      return DraftInvalid({for (final issue in issues) _fieldFor(issue): profileIssueMessage(issue)});
    }
    return DraftValid(profile);
  }
}

sealed class DraftResult {
  const DraftResult();
}

final class DraftValid extends DraftResult {
  const DraftValid(this.profile);

  final HealthProfile profile;
}

final class DraftInvalid extends DraftResult {
  DraftInvalid(Map<ProfileField, String> errors) : errors = Map.unmodifiable(errors);

  final Map<ProfileField, String> errors;
}

String? _numberError(String text, double? value, String fieldName) {
  if (text.trim().isEmpty) {
    return 'Nhập $fieldName.';
  }
  return value == null ? 'Chỉ nhập số, ví dụ 58.5 hoặc 58,5.' : null;
}

String? _textOrNull(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

ProfileField _fieldFor(ProfileIssue issue) => switch (issue) {
  ProfileIssue.birthDateInFuture || ProfileIssue.birthDateTooOld => ProfileField.birthDate,
  ProfileIssue.bmrFormulaMissing => ProfileField.bmrFormula,
  ProfileIssue.heightOutOfRange => ProfileField.height,
  ProfileIssue.weightOutOfRange => ProfileField.weight,
  ProfileIssue.targetWeightOutOfRange => ProfileField.targetWeight,
  ProfileIssue.weeklyChangeMissing || ProfileIssue.weeklyChangeOutOfRange => ProfileField.weeklyChange,
};
