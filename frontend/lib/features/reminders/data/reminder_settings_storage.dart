import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/features/reminders/domain/reminder_settings.dart';
import 'package:fluw/features/reminders/domain/reminder_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reminder settings are preferences, not health data, so they live in shared_preferences. Without a store (it failed
/// to open at start) or on any read or write error, the defaults apply (reminders off) instead of failing the app.
class ReminderSettingsStorage {
  const ReminderSettingsStorage(this._preferences);

  static const String enabledKey = 'reminders_enabled';
  static const String timesKey = 'reminder_times';

  final SharedPreferences? _preferences;

  ReminderSettings load() {
    final preferences = _preferences;
    if (preferences == null) {
      return ReminderSettings.defaults;
    }
    try {
      final stored = preferences.getStringList(timesKey)?.map(ReminderTime.tryParse).nonNulls.toList();
      return ReminderSettings(
        enabled: preferences.getBool(enabledKey) ?? false,
        times: stored == null || stored.isEmpty ? ReminderSettings.defaultTimes : stored,
      );
    } on Object {
      return ReminderSettings.defaults;
    }
  }

  Future<void> save(ReminderSettings settings) async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    try {
      await preferences.setBool(enabledKey, settings.enabled);
      await preferences.setStringList(timesKey, [for (final time in settings.times) time.label]);
    } on Object {
      // The in-memory settings still apply until the app restarts.
    }
  }
}

final reminderSettingsStorageProvider = Provider<ReminderSettingsStorage>(
  (ref) => throw UnimplementedError('reminderSettingsStorageProvider phải được nối trong main()'),
);
