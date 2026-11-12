final class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(this.year, this.month, this.day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year || normalized.month != month || normalized.day != day) {
      throw ArgumentError('Ngày không tồn tại: $year-$month-$day');
    }
  }

  /// Takes the date fields of [dateTime] in its own zone; pass `DateTime.now()` for the user's local today.
  CalendarDate.fromDateTime(DateTime dateTime) : this(dateTime.year, dateTime.month, dateTime.day);

  /// Reads the `yyyy-MM-dd` form written by [toString]; returns `null` for anything else or a date that does not exist.
  static CalendarDate? tryParse(String text) {
    final match = _isoDate.firstMatch(text);
    if (match == null) {
      return null;
    }
    final [year, month, day] = [for (var group = 1; group <= 3; group++) int.parse(match.group(group)!)];
    try {
      return CalendarDate(year, month, day);
    } on ArgumentError {
      return null;
    }
  }

  static final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  CalendarDate addDays(int days) => CalendarDate.fromDateTime(DateTime.utc(year, month, day + days));

  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) {
      return year.compareTo(other.year);
    }
    if (month != other.month) {
      return month.compareTo(other.month);
    }
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
