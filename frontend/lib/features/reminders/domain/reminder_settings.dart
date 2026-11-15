import 'package:collection/collection.dart';
import 'package:fluw/features/reminders/domain/reminder_time.dart';

/// Off until the user turns it on, so the notification permission is asked when they want reminders, not at first
/// launch. The default times are the ones FLuw chose.
final class ReminderSettings {
  ReminderSettings({required this.enabled, required List<ReminderTime> times})
    : times = List.unmodifiable({...times}.toList()..sort());

  static final List<ReminderTime> defaultTimes = List.unmodifiable(const [
    ReminderTime(10, 0),
    ReminderTime(17, 0),
    ReminderTime(22, 0),
  ]);

  static final ReminderSettings defaults = ReminderSettings(enabled: false, times: defaultTimes);

  final bool enabled;

  /// Sorted, without duplicates.
  final List<ReminderTime> times;

  ReminderSettings copyWith({bool? enabled, List<ReminderTime>? times}) =>
      ReminderSettings(enabled: enabled ?? this.enabled, times: times ?? this.times);

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      const ListEquality<ReminderTime>().equals(other.times, times);

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(times));
}
