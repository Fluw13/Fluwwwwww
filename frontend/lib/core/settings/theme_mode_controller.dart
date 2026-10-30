import 'package:flutter/material.dart';

import 'theme_mode_store.dart';

class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._store, {this.readTimeout = const Duration(seconds: 2)});

  final ThemeModeStore _store;
  final Duration readTimeout;

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Runs before the first frame, so any storage failure or a platform channel
  /// that never answers falls back to following the device instead of keeping
  /// the app on its splash screen.
  Future<void> load() async {
    try {
      final ThemeMode? stored = await _store.read().timeout(readTimeout);
      if (stored == null || stored == _mode) return;
      _mode = stored;
      notifyListeners();
    } catch (error) {
      debugPrint('ThemeModeController.load failed, following the device theme: $error');
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();

    try {
      await _store.write(mode);
    } catch (error) {
      debugPrint('ThemeModeController.setMode could not persist $mode: $error');
    }
  }
}
