/// A local time of day for a reminder, stored as "HH:mm".
final class ReminderTime implements Comparable<ReminderTime> {
  const ReminderTime(this.hour, this.minute);

  final int hour;
  final int minute;

  static ReminderTime? tryParse(String text) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(text);
    if (match == null) {
      return null;
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return hour < 24 && minute < 60 ? ReminderTime(hour, minute) : null;
  }

  String get label => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ReminderTime other) => (hour * 60 + minute) - (other.hour * 60 + other.minute);

  @override
  bool operator ==(Object other) => other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => label;
}
