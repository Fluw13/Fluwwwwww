import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/logged_food.dart';

/// Lets any feature add a food to the diary without importing the diary feature; `app/` provides the real one.
abstract interface class FoodLogger {
  Future<void> log(LoggedFood food);
}

final foodLoggerProvider = Provider<FoodLogger>(
  (ref) => throw UnimplementedError('foodLoggerProvider phải được nối trong app/app_overrides.dart'),
);
