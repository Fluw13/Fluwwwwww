import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/app/fluw_app.dart';
import 'package:fluw/core/licenses/font_licenses.dart';
import 'package:fluw/core/settings/preferences_loader.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final preferences = await loadPreferences();

  runApp(
    ProviderScope(
      overrides: [themeModeStorageProvider.overrideWithValue(ThemeModeStorage(preferences))],
      child: const FluwApp(),
    ),
  );
}
