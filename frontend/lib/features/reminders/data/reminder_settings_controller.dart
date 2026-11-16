import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/features/reminders/data/reminder_settings_storage.dart';
import 'package:fluw/features/reminders/domain/reminder_settings.dart';

final reminderSettingsProvider = NotifierProvider<ReminderSettingsController, ReminderSettings>(
  ReminderSettingsController.new,
);

class ReminderSettingsController extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() => ref.watch(reminderSettingsStorageProvider).load();

  Future<void> update(ReminderSettings settings) async {
    state = settings;
    await ref.read(reminderSettingsStorageProvider).save(settings);
  }
}
