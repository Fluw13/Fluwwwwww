import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/time/calendar_date.dart';

/// The user's local date; tests override it so ages and targets do not change with the real calendar.
/// Refreshes itself just after local midnight, so a screen left open overnight does not keep yesterday.
final todayProvider = Provider<CalendarDate>((ref) {
  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(nextMidnight.difference(now) + const Duration(seconds: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return CalendarDate.fromDateTime(now);
});
