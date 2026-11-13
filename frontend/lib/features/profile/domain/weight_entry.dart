import 'package:fluw/core/time/calendar_date.dart';

/// One weigh-in per day; logging again on the same day replaces it.
final class WeightEntry {
  const WeightEntry({required this.date, required this.weightKg});

  final CalendarDate date;
  final double weightKg;

  @override
  bool operator ==(Object other) => other is WeightEntry && other.date == date && other.weightKg == weightKg;

  @override
  int get hashCode => Object.hash(date, weightKg);
}
