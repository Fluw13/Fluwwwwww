import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

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
}
