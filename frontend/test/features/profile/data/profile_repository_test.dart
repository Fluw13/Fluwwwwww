import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

import '../../../helpers/in_memory_database.dart';
import '../domain/profile_fixture.dart';

Matcher _loaded(HealthProfile profile) => isA<LoadedProfile>().having((stored) => stored.profile, 'profile', profile);

void main() {
  late AppDatabase database;
  late ProfileRepository repository;

  setUp(() {
    database = openInMemoryDatabase();
    repository = ProfileRepository(database);
  });
  tearDown(() => database.close());

  test('chưa thiết lập thì không có hồ sơ', () async {
    expect(await repository.load(), isA<NoProfile>());
  });

  test('lưu rồi đọc lại khớp từng trường', () async {
    final profile = buildProfile(
      displayName: 'Lê An',
      sex: Sex.other,
      bmrFormulaForOther: BmrFormula.female,
      birthDate: CalendarDate(1990, 2, 28),
      heightCm: 158.5,
      weightKg: 52.3,
      targetWeightKg: 50.1,
      activityLevel: ActivityLevel.veryActive,
      trainingType: TrainingType.endurance,
      weeklyChangeKg: 0.25,
      conditions: {HealthCondition.diabetes, HealthCondition.lowBloodPressure, HealthCondition.gout},
      conditionNote: 'Hen suyễn nhẹ',
      limitsSugar: true,
      dietary: DietaryPreferences(
        allergies: {Allergen.crustaceans: AllergySeverity.severe, Allergen.peanuts: AllergySeverity.mild},
        allergyNote: 'Kiwi',
        dietStyle: DietStyle.mediterranean,
        preferences: {FoodPreference.noOrganMeat, FoodPreference.likesNuts},
      ),
    );

    await repository.save(profile);

    expect(await repository.load(), _loaded(profile));
  });

  test('số nhiều chữ số thập phân và ghi chú rỗng đọc lại y nguyên', () async {
    final profile = buildProfile(
      heightCm: 172.345678,
      weightKg: 68.123456789,
      targetWeightKg: 64.987654321,
      weeklyChangeKg: 0.333333333,
      conditionNote: '',
    );

    await repository.save(profile);

    expect(await repository.load(), _loaded(profile));
  });

  test('số không hữu hạn bị từ chối trước khi chạm vào database', () async {
    final invalid = [
      buildProfile(weightKg: double.nan),
      buildProfile(heightCm: double.infinity),
      buildProfile(targetWeightKg: double.negativeInfinity),
      buildProfile(weeklyChangeKg: double.nan),
    ];

    for (final profile in invalid) {
      await expectLater(repository.save(profile), throwsArgumentError);
    }
    expect(await repository.load(), isA<NoProfile>());
  });

  test('trường để trống và danh sách bệnh rỗng vẫn đọc lại đúng', () async {
    final profile = buildProfile(weeklyChangeKg: null, targetWeightKg: 70, conditions: {}, conditionNote: null);

    await repository.save(profile);

    expect(await repository.load(), _loaded(profile));
  });

  test('lưu lần hai thay hẳn hồ sơ cũ, kể cả bỏ bớt bệnh', () async {
    await repository.save(buildProfile(conditions: {HealthCondition.diabetes, HealthCondition.gout}));
    final updated = buildProfile(weightKg: 68, conditions: {HealthCondition.hypertension});

    await repository.save(updated);

    expect(await repository.load(), _loaded(updated));
    expect(await database.select(database.profiles).get(), hasLength(1));
  });

  test('xóa hồ sơ thì xóa cả danh sách bệnh', () async {
    await repository.save(buildProfile(conditions: {HealthCondition.diabetes}));

    await repository.clear();

    expect(await repository.load(), isA<NoProfile>());
    expect(await database.select(database.profileConditions).get(), isEmpty);
  });

  test('khóa bệnh lạ (vd từ bản app mới hơn) bị bỏ qua, các bệnh khác vẫn đọc được', () async {
    await repository.save(buildProfile(conditions: {HealthCondition.gout}));
    await database.into(database.profileConditions).insert(ProfileConditionsCompanion.insert(conditionKey: 'asthma'));

    expect(await repository.load(), _loaded(buildProfile(conditions: {HealthCondition.gout})));
  });

  test('trường bắt buộc không đọc được thì báo hồ sơ hỏng, khác với chưa có hồ sơ, không crash', () async {
    final corruptions = <ProfilesCompanion>[
      const ProfilesCompanion(sex: Value('unknown')),
      const ProfilesCompanion(birthDate: Value('13/05/2006')),
      const ProfilesCompanion(activityLevel: Value('extreme')),
      const ProfilesCompanion(trainingType: Value('crossfit')),
    ];

    for (final corruption in corruptions) {
      await repository.save(buildProfile());
      await database.update(database.profiles).write(corruption);

      expect(await repository.load(), isA<UnreadableProfile>(), reason: '$corruption');
    }
  });

  test('khóa công thức BMR lạ đọc thành "chưa chọn", hồ sơ vẫn đọc được', () async {
    await repository.save(buildProfile(sex: Sex.other, bmrFormulaForOther: BmrFormula.male));
    await database.update(database.profiles).write(const ProfilesCompanion(bmrFormula: Value('neutral')));

    expect(await repository.load(), _loaded(buildProfile(sex: Sex.other)));
  });

  test('dị ứng lạ (vd từ bản app mới hơn) thì báo hồ sơ hỏng, không âm thầm tắt cảnh báo', () async {
    await repository.save(buildProfile());
    await database
        .into(database.profileAllergies)
        .insert(ProfileAllergiesCompanion.insert(allergenKey: 'kiwi', severityKey: 'severe'));

    expect(await repository.load(), isA<UnreadableProfile>());
  });

  test('mức dị ứng lạ đọc thành Nặng; chế độ ăn lạ thành Bình thường; sở thích lạ bị bỏ qua', () async {
    await repository.save(buildProfile());
    await database
        .into(database.profileAllergies)
        .insert(ProfileAllergiesCompanion.insert(allergenKey: 'milk', severityKey: 'extreme'));
    await database.into(database.profilePreferences).insert(ProfilePreferencesCompanion.insert(preferenceKey: 'raw'));
    await database.update(database.profiles).write(const ProfilesCompanion(dietStyle: Value('paleo')));

    final dietary = ((await repository.load()) as LoadedProfile).profile.dietary;
    expect(dietary.allergies, {Allergen.milk: AllergySeverity.severe});
    expect(dietary.dietStyle, DietStyle.regular);
    expect(dietary.preferences, isEmpty);
  });

  test('watch phát lại khi chỉ bảng dị ứng đổi', () async {
    await repository.save(buildProfile());
    final emitted = <StoredProfile>[];
    final subscription = repository.watch().listen(emitted.add);
    await pumpEventQueue();

    await database
        .into(database.profileAllergies)
        .insert(ProfileAllergiesCompanion.insert(allergenKey: 'eggs', severityKey: 'mild'));
    await pumpEventQueue();
    await subscription.cancel();

    expect((emitted.last as LoadedProfile).profile.dietary.allergies, {Allergen.eggs: AllergySeverity.mild});
  });

  test('hướng mục tiêu đã lưu được giữ khi cân nặng vượt mục tiêu; dòng cũ thiếu cột thì suy từ cân nặng', () async {
    final reached = buildProfile(weightKg: 64.8, targetWeightKg: 65, plannedGoal: WeightGoal.lose);
    await repository.save(reached);
    expect(await repository.load(), _loaded(reached));

    await database.update(database.profiles).write(const ProfilesCompanion(plannedGoal: Value(null)));
    expect(((await repository.load()) as LoadedProfile).profile.plannedGoal, WeightGoal.gain);
  });

  test('lưu lại sau khi bỏ dị ứng và thói quen thì dòng cũ mất hẳn', () async {
    await repository.save(
      buildProfile(
        dietary: DietaryPreferences(
          allergies: {Allergen.fish: AllergySeverity.severe, Allergen.milk: AllergySeverity.mild},
          allergyNote: null,
          dietStyle: DietStyle.keto,
          preferences: {FoodPreference.likesNuts, FoodPreference.noOrganMeat},
        ),
      ),
    );
    final trimmed = buildProfile(
      dietary: DietaryPreferences(
        allergies: {Allergen.milk: AllergySeverity.mild},
        allergyNote: null,
        dietStyle: DietStyle.keto,
        preferences: {FoodPreference.likesNuts},
      ),
    );

    await repository.save(trimmed);

    expect(await repository.load(), _loaded(trimmed));
    expect(await database.select(database.profileAllergies).get(), hasLength(1));
    expect(await database.select(database.profilePreferences).get(), hasLength(1));
  });

  test('xóa hồ sơ thì xóa cả dị ứng, thói quen và lịch sử cân', () async {
    await repository.save(
      buildProfile(
        dietary: DietaryPreferences(
          allergies: {Allergen.fish: AllergySeverity.severe},
          allergyNote: null,
          dietStyle: DietStyle.regular,
          preferences: {FoodPreference.likesNuts},
        ),
      ),
    );
    await database.into(database.weightEntries).insert(WeightEntriesCompanion.insert(date: '2026-11-11', weightKg: 70));

    await repository.clear();

    expect(await database.select(database.profileAllergies).get(), isEmpty);
    expect(await database.select(database.profilePreferences).get(), isEmpty);
    expect(await database.select(database.weightEntries).get(), isEmpty);
  });

  test('watch phát lại khi chỉ bảng thói quen đổi', () async {
    await repository.save(buildProfile());
    final emitted = <StoredProfile>[];
    final subscription = repository.watch().listen(emitted.add);
    await pumpEventQueue();

    await database
        .into(database.profilePreferences)
        .insert(ProfilePreferencesCompanion.insert(preferenceKey: 'likes_nuts'));
    await pumpEventQueue();
    await subscription.cancel();

    expect((emitted.last as LoadedProfile).profile.dietary.preferences, {FoodPreference.likesNuts});
  });

  test('watch phát lại mỗi khi lưu, đổi bệnh hoặc xóa', () async {
    final first = buildProfile(conditions: {HealthCondition.diabetes});
    final second = first.copyWith(conditions: {HealthCondition.diabetes, HealthCondition.hypertension});
    final emitted = <StoredProfile>[];
    final subscription = repository.watch().listen(emitted.add);

    Future<void> settle() => pumpEventQueue();
    await settle();
    await repository.save(first);
    await settle();
    await repository.save(second);
    await settle();
    await repository.clear();
    await settle();
    await subscription.cancel();

    expect(emitted, [isA<NoProfile>(), _loaded(first), _loaded(second), isA<NoProfile>()]);
  });
}
