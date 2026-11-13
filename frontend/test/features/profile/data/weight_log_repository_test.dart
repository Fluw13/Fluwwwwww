import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/data/weight_log_repository.dart';
import 'package:fluw/features/profile/domain/weight_entry.dart';

import '../../../helpers/in_memory_database.dart';
import '../domain/profile_fixture.dart';

void main() {
  late AppDatabase database;
  late WeightLogRepository weightLog;
  late ProfileRepository profiles;

  setUp(() async {
    database = openInMemoryDatabase();
    weightLog = WeightLogRepository(database);
    profiles = ProfileRepository(database);
    await profiles.save(buildProfile(weightKg: 70));
  });
  tearDown(() => database.close());

  Future<double> profileWeight() async => ((await profiles.load()) as LoadedProfile).profile.weightKg;

  test('ghi cân nặng thì lưu vào lịch sử và thành cân nặng hiện tại của hồ sơ', () async {
    final entry = WeightEntry(date: CalendarDate(2026, 11, 11), weightKg: 69.4);

    await weightLog.record(entry);

    expect(await weightLog.watch().first, [entry]);
    expect(await profileWeight(), 69.4);
  });

  test('ghi lại cùng ngày thì thay số cũ; lịch sử xếp từ cũ đến mới', () async {
    await weightLog.record(WeightEntry(date: CalendarDate(2026, 11, 11), weightKg: 69.4));
    await weightLog.record(WeightEntry(date: CalendarDate(2026, 11, 4), weightKg: 70.2));
    await weightLog.record(WeightEntry(date: CalendarDate(2026, 11, 11), weightKg: 69.1));

    expect(await weightLog.watch().first, [
      WeightEntry(date: CalendarDate(2026, 11, 4), weightKg: 70.2),
      WeightEntry(date: CalendarDate(2026, 11, 11), weightKg: 69.1),
    ]);
    expect(await profileWeight(), 69.1);
  });

  test('ghi bù một ngày cũ hơn thì không đổi cân nặng hiện tại', () async {
    await weightLog.record(WeightEntry(date: CalendarDate(2026, 11, 11), weightKg: 69.4));
    await weightLog.record(WeightEntry(date: CalendarDate(2026, 11, 1), weightKg: 71));

    expect(await profileWeight(), 69.4);
  });

  test('số không hữu hạn bị từ chối, không ghi gì', () async {
    await expectLater(
      weightLog.record(WeightEntry(date: CalendarDate(2026, 11, 11), weightKg: double.nan)),
      throwsArgumentError,
    );
    expect(await weightLog.watch().first, isEmpty);
    expect(await profileWeight(), 70);
  });
}
