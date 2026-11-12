import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';

import '../../../helpers/in_memory_database.dart';
import '../domain/profile_fixture.dart';

void main() {
  late AppDatabase database;
  late ProfileRepository repository;

  setUp(() {
    database = openInMemoryDatabase();
    repository = ProfileRepository(database);
  });
  tearDown(() => database.close());

  test('chưa thiết lập thì không có hồ sơ', () async {
    expect(await repository.load(), isNull);
  });

  test('lưu rồi đọc lại khớp từng trường', () async {
    final profile = buildProfile(
      sex: Sex.female,
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
    );

    await repository.save(profile);

    expect(await repository.load(), profile);
  });

  test('trường để trống và danh sách bệnh rỗng vẫn đọc lại đúng', () async {
    final profile = buildProfile(weeklyChangeKg: null, targetWeightKg: 70, conditions: {}, conditionNote: null);

    await repository.save(profile);

    expect(await repository.load(), profile);
  });

  test('lưu lần hai thay hẳn hồ sơ cũ, kể cả bỏ bớt bệnh', () async {
    await repository.save(buildProfile(conditions: {HealthCondition.diabetes, HealthCondition.gout}));
    final updated = buildProfile(weightKg: 68, conditions: {HealthCondition.hypertension});

    await repository.save(updated);

    expect(await repository.load(), updated);
    expect(await database.select(database.profiles).get(), hasLength(1));
  });

  test('xóa hồ sơ thì xóa cả danh sách bệnh', () async {
    await repository.save(buildProfile(conditions: {HealthCondition.diabetes}));

    await repository.clear();

    expect(await repository.load(), isNull);
    expect(await database.select(database.profileConditions).get(), isEmpty);
  });

  test('khóa bệnh lạ (vd từ bản app mới hơn) bị bỏ qua, các bệnh khác vẫn đọc được', () async {
    await repository.save(buildProfile(conditions: {HealthCondition.gout}));
    await database.into(database.profileConditions).insert(ProfileConditionsCompanion.insert(conditionKey: 'asthma'));

    expect((await repository.load())?.conditions, {HealthCondition.gout});
  });

  test('trường bắt buộc có giá trị không đọc được thì coi như chưa có hồ sơ, không crash', () async {
    final corruptions = <ProfilesCompanion>[
      const ProfilesCompanion(sex: Value('other')),
      const ProfilesCompanion(birthDate: Value('13/05/2006')),
      const ProfilesCompanion(activityLevel: Value('extreme')),
      const ProfilesCompanion(trainingType: Value('crossfit')),
    ];

    for (final corruption in corruptions) {
      await repository.save(buildProfile());
      await database.update(database.profiles).write(corruption);

      expect(await repository.load(), isNull, reason: '$corruption');
    }
  });

  test('watch phát lại mỗi khi lưu, đổi bệnh hoặc xóa', () async {
    final first = buildProfile(conditions: {HealthCondition.diabetes});
    final second = first.copyWith(conditions: {HealthCondition.diabetes, HealthCondition.hypertension});
    final emitted = <Object?>[];
    final subscription = repository.watch().distinct().listen(emitted.add);

    Future<void> settle() => pumpEventQueue();
    await settle();
    await repository.save(first);
    await settle();
    await repository.save(second);
    await settle();
    await repository.clear();
    await settle();
    await subscription.cancel();

    expect(emitted, [null, first, second, null]);
  });
}
