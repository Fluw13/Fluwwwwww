import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/time/calendar_date.dart';

/// The user's local date; tests override it so ages and targets do not change with the real calendar.
final todayProvider = Provider<CalendarDate>((ref) => CalendarDate.fromDateTime(DateTime.now()));
