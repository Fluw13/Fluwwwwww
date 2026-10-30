import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_mode_store.dart';

/// Keeps the chosen theme on this device only; nothing is synced or sent anywhere.
class SharedPrefsThemeModeStore implements ThemeModeStore {
  SharedPrefsThemeModeStore({SharedPreferencesAsync? preferences}) : _injected = preferences;

  static const String storageKey = 'theme_mode';

  final SharedPreferencesAsync? _injected;
  SharedPreferencesAsync? _created;

  // Created on first use so a missing platform implementation surfaces inside
  // read/write, where the controller handles it, instead of in main().
  SharedPreferencesAsync get _preferences => _injected ?? (_created ??= SharedPreferencesAsync());

  @override
  Future<ThemeMode?> read() async {
    final String? stored = await _preferences.getString(storageKey);
    for (final ThemeMode mode in ThemeMode.values) {
      if (mode.name == stored) return mode;
    }
    return null;
  }

  @override
  Future<void> write(ThemeMode mode) => _preferences.setString(storageKey, mode.name);
}
