import 'package:flutter/material.dart';

abstract interface class ThemeModeStore {
  Future<ThemeMode?> read();

  Future<void> write(ThemeMode mode);
}
