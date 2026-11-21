import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class ThemeModeStorage {
  const ThemeModeStorage(this._preferences);

  static const String key = 'theme_mode';

  final SharedPreferences? _preferences;

  ThemeMode read() {
    final stored = _preferences?.getString(key);
    return ThemeMode.values.firstWhere((mode) => mode.name == stored, orElse: () => ThemeMode.system);
  }

  /// A failed write only means the choice is not remembered after a restart.
  Future<void> write(ThemeMode mode) async {
    try {
      await _preferences?.setString(key, mode.name);
    } on Exception {
      return;
    }
  }
}
