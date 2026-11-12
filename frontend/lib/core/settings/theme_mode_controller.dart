import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';

final themeModeStorageProvider = Provider<ThemeModeStorage>(
  (ref) => throw UnimplementedError('themeModeStorageProvider phải được khởi tạo trong main()'),
);

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

final class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(themeModeStorageProvider).read();

  void select(ThemeMode mode) {
    state = mode;
    unawaited(ref.read(themeModeStorageProvider).write(mode));
  }
}
