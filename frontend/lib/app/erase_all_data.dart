import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/search/search_request.dart';
import 'package:fluw/core/settings/shared_preferences_provider.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:fluw/features/reminders/data/notification_scheduler.dart';
import 'package:fluw/features/reminders/data/reminder_settings_controller.dart';
import 'package:fluw/features/reminders/domain/reminder_settings.dart';
import 'package:fluw/features/search/presentation/recent_searches_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Erases everything Fluw keeps on this phone except the light/dark choice: every database table (profile and its
/// lists, weigh-ins, diary), every setting (reminders, recent searches, photo and health data consent) and the
/// pending reminders. Every step runs even when an earlier one fails, then the first failure is rethrown, so trying
/// again finishes the job.
final eraseAllDataProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => _eraseAllData(ref),
);

/// Settings that are not personal data and survive the erase.
const Set<String> _keptSettings = {ThemeModeStorage.key};

Future<void> _eraseAllData(Ref ref) async {
  Object? failure;
  StackTrace? failureStack;
  Future<void> step(Future<void> Function() run) async {
    try {
      await run();
    } on Object catch (error, stack) {
      failure ??= error;
      failureStack ??= stack;
    }
  }

  // Reminders go first: once they are off, emptying the diary and profile cannot schedule new reminder texts.
  await step(() => ref.read(reminderSettingsProvider.notifier).update(ReminderSettings.defaults));
  await step(() => ref.read(notificationSchedulerProvider).replaceAll(const []));
  await step(() => _eraseDatabase(ref.read(appDatabaseProvider)));
  await step(() => ref.read(recentSearchesProvider.notifier).clear());
  await step(() => _eraseSettings(ref.read(sharedPreferencesProvider)));
  // Choices made in memory for the next food to log or search, which must not outlive the data they came from.
  ref
    ..invalidate(diaryTargetProvider)
    ..invalidate(searchRequestProvider);

  if (failure case final error?) {
    Error.throwWithStackTrace(error, failureStack!);
  }
}

/// Every table, so tables added later are erased too. VACUUM rewrites the file, so the deleted rows do not linger in
/// its free pages (or in a device backup of it).
Future<void> _eraseDatabase(AppDatabase database) async {
  await database.transaction(() async {
    for (final table in database.allTables) {
      await database.delete(table).go();
    }
  });
  await database.customStatement('VACUUM');
}

Future<void> _eraseSettings(SharedPreferences? preferences) async {
  if (preferences == null) {
    throw StateError('Không mở được kho cài đặt nên chưa xóa được cài đặt');
  }
  for (final key in preferences.getKeys().difference(_keptSettings)) {
    await preferences.remove(key);
  }
}
