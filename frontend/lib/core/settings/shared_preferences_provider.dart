import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The settings store opened in `main()`; `null` when it failed to open, and the app then runs on default settings.
final sharedPreferencesProvider = Provider<SharedPreferences?>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider phải được nối trong main()'),
);
