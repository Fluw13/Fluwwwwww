import 'package:fluw/core/time/calendar_date.dart';

String weekdayShortLabel(CalendarDate day) => switch (DateTime.utc(day.year, day.month, day.day).weekday) {
  DateTime.monday => 'Th 2',
  DateTime.tuesday => 'Th 3',
  DateTime.wednesday => 'Th 4',
  DateTime.thursday => 'Th 5',
  DateTime.friday => 'Th 6',
  DateTime.saturday => 'Th 7',
  _ => 'CN',
};

String monthLabel(CalendarDate day) => 'Tháng ${day.month}, ${day.year}';

String timeLabel(DateTime time) {
  final local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
