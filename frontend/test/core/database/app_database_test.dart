import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/profile_tables.dart';

import '../../helpers/in_memory_database.dart';

ProfilesCompanion _row({required int id}) => ProfilesCompanion.insert(
  id: Value(id),
  sex: 'male',
  birthDate: '2006-05-13',
  heightCm: 175,
  weightKg: 70,
  targetWeightKg: 65,
  activityLevel: 'moderate',
  trainingType: 'strength',
  limitsSugar: false,
);

void main() {
  late AppDatabase database;

  setUp(() => database = openInMemoryDatabase());
  tearDown(() => database.close());

  test('tạo được các bảng của phiên bản schema hiện tại', () async {
    final tables = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name")
        .map((row) => row.read<String>('name'))
        .get();

    expect(
      tables,
      containsAll(['profiles', 'profile_conditions', 'profile_allergies', 'profile_preferences', 'weight_entries']),
    );
    expect(database.schemaVersion, 3);
  });

  test('bảng hồ sơ chỉ nhận đúng một dòng có id cố định', () async {
    await database.into(database.profiles).insert(_row(id: singleProfileId));

    await expectLater(database.into(database.profiles).insert(_row(id: 2)), throwsA(isA<Exception>()));
    expect(await database.select(database.profiles).get(), hasLength(1));
  });
}
