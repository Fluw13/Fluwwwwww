import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/erase_all_data.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/settings/shared_preferences_provider.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/reminders/data/notification_scheduler.dart';
import 'package:fluw/features/reminders/data/reminder_settings_storage.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';
import 'package:fluw/features/search/data/recent_searches_storage.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/profile/domain/profile_fixture.dart';
import '../helpers/fake_notification_scheduler.dart';
import '../helpers/in_memory_database.dart';

/// Fails every call, like a notification plugin that is broken on this phone.
final class _BrokenScheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async => throw StateError('plugin hỏng');
}

void main() {
  late AppDatabase database;

  setUp(() => database = openInMemoryDatabase());
  tearDown(() => database.close());

  ProviderContainer containerWith({required SharedPreferences? preferences, required NotificationScheduler scheduler}) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(preferences),
        notificationSchedulerProvider.overrideWithValue(scheduler),
        reminderSettingsStorageProvider.overrideWithValue(ReminderSettingsStorage(preferences)),
        recentSearchesStorageProvider.overrideWithValue(RecentSearchesStorage(preferences)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<int> totalRows() async {
    var total = 0;
    for (final table in database.allTables) {
      total += (await database.select(table).get()).length;
    }
    return total;
  }

  test('xóa mọi bảng và mọi khóa cài đặt trừ Sáng/Tối, kể cả khóa của tính năng thêm sau này', () async {
    SharedPreferences.setMockInitialValues({
      ThemeModeStorage.key: 'light',
      ReminderSettingsStorage.enabledKey: true,
      'khoa_cua_tinh_nang_moi': 1,
    });
    final preferences = await SharedPreferences.getInstance();
    await ProfileRepository(database).save(buildProfile());
    final scheduler = FakeNotificationScheduler();

    await containerWith(preferences: preferences, scheduler: scheduler).read(eraseAllDataProvider)();

    expect(await totalRows(), 0);
    expect(preferences.getKeys(), {ThemeModeStorage.key});
    expect(scheduler.scheduled, [isEmpty], reason: 'hủy nhắc đang chờ trên máy đúng một lần');
  });

  test('một bước lỗi thì các bước sau vẫn chạy, rồi báo lỗi đầu tiên để thử lại', () async {
    SharedPreferences.setMockInitialValues({
      'recent_searches': <String>['phở'],
    });
    final preferences = await SharedPreferences.getInstance();
    await ProfileRepository(database).save(buildProfile());

    final erase = containerWith(preferences: preferences, scheduler: _BrokenScheduler()).read(eraseAllDataProvider);

    await expectLater(erase(), throwsA(isA<StateError>().having((error) => error.message, 'message', 'plugin hỏng')));
    expect(await totalRows(), 0);
    expect(preferences.getKeys(), isEmpty);
  });

  test('không mở được kho cài đặt thì vẫn xóa dữ liệu trên máy nhưng báo lỗi', () async {
    await ProfileRepository(database).save(buildProfile());
    final scheduler = FakeNotificationScheduler();

    await expectLater(
      containerWith(preferences: null, scheduler: scheduler).read(eraseAllDataProvider)(),
      throwsStateError,
    );
    expect(await totalRows(), 0);
    expect(scheduler.scheduled, [isEmpty]);
  });
}
