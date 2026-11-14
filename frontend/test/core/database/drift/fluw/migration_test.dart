import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (final (index, fromVersion) in GeneratedHelper.versions.indexed) {
    for (final toVersion in GeneratedHelper.versions.skip(index + 1)) {
      test('nâng schema từ v$fromVersion lên v$toVersion cho ra đúng cấu trúc đã lưu', () async {
        final schema = await verifier.schemaAt(fromVersion);
        final database = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(database, toVersion);
        await database.close();
      });
    }
  }

  test('v1 lên v2 giữ nguyên hồ sơ và bệnh đã lưu, cột mới để trống', () async {
    const oldProfile = v1.ProfilesData(
      id: 1,
      sex: 'female',
      birthDate: '1998-03-04',
      heightCm: 165,
      weightKg: 58.5,
      targetWeightKg: 53,
      activityLevel: 'light',
      trainingType: 'endurance',
      weeklyChangeKg: 0.25,
      conditionNote: 'Hen suyễn',
      limitsSugar: 1,
    );
    const expectedProfile = v2.ProfilesData(
      id: 1,
      displayName: null,
      sex: 'female',
      bmrFormula: null,
      birthDate: '1998-03-04',
      heightCm: 165,
      weightKg: 58.5,
      targetWeightKg: 53,
      activityLevel: 'light',
      trainingType: 'endurance',
      weeklyChangeKg: 0.25,
      conditionNote: 'Hen suyễn',
      limitsSugar: 1,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.profiles, oldProfile);
        batch.insertAll(oldDb.profileConditions, const [
          v1.ProfileConditionsData(conditionKey: 'diabetes'),
          v1.ProfileConditionsData(conditionKey: 'gout'),
        ]);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.profiles).get(), [expectedProfile]);
        expect(await newDb.select(newDb.profileConditions).get(), const [
          v2.ProfileConditionsData(conditionKey: 'diabetes'),
          v2.ProfileConditionsData(conditionKey: 'gout'),
        ]);
      },
    );
  });

  test('v2 lên v3 giữ nguyên hồ sơ, tên và công thức BMR; cột và bảng mới để trống', () async {
    const oldProfile = v2.ProfilesData(
      id: 1,
      displayName: 'An',
      sex: 'other',
      bmrFormula: 'female',
      birthDate: '1998-03-04',
      heightCm: 165,
      weightKg: 58.5,
      targetWeightKg: 53,
      activityLevel: 'light',
      trainingType: 'endurance',
      weeklyChangeKg: 0.25,
      conditionNote: null,
      limitsSugar: 0,
    );
    const expectedProfile = v3.ProfilesData(
      id: 1,
      displayName: 'An',
      sex: 'other',
      bmrFormula: 'female',
      birthDate: '1998-03-04',
      heightCm: 165,
      weightKg: 58.5,
      targetWeightKg: 53,
      activityLevel: 'light',
      trainingType: 'endurance',
      weeklyChangeKg: 0.25,
      conditionNote: null,
      limitsSugar: 0,
      dietStyle: null,
      allergyNote: null,
      plannedGoal: null,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.profiles, oldProfile);
        batch.insert(oldDb.profileConditions, const v2.ProfileConditionsData(conditionKey: 'diabetes'));
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.profiles).get(), [expectedProfile]);
        expect(await newDb.select(newDb.profileConditions).get(), const [
          v3.ProfileConditionsData(conditionKey: 'diabetes'),
        ]);
        expect(await newDb.select(newDb.profileAllergies).get(), isEmpty);
        expect(await newDb.select(newDb.weightEntries).get(), isEmpty);
      },
    );
  });

  test('v3 lên v4 giữ nguyên lịch sử cân, bảng Nhật ký mới để trống', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.weightEntries, const v3.WeightEntriesData(date: '2026-11-10', weightKg: 60.5));
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.weightEntries).get(), const [
          v4.WeightEntriesData(date: '2026-11-10', weightKg: 60.5),
        ]);
        expect(await newDb.select(newDb.noteEntries).get(), isEmpty);
      },
    );
  });
}
