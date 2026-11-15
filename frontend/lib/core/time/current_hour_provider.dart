import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The local hour, refreshed at the next full hour, for texts that depend on the time of day (evening advice) on
/// screens that stay mounted. Tests override it with a fixed hour.
final currentHourProvider = Provider<int>((ref) {
  final now = DateTime.now();
  final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
  final timer = Timer(nextHour.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return now.hour;
});
