import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/app/app_overrides.dart';
import 'package:fluw/app/fluw_app.dart';
import 'package:fluw/core/licenses/data_licenses.dart';
import 'package:fluw/core/licenses/font_licenses.dart';
import 'package:fluw/core/network/api_client_provider.dart';
import 'package:fluw/core/network/backend_warm_up.dart';
import 'package:fluw/core/settings/preferences_loader.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:fluw/features/search/data/recent_searches_storage.dart';
import 'package:fluw/features/search/data/search_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  registerDataLicenses();
  final preferences = await loadPreferences();
  final container = ProviderContainer(
    overrides: [
      themeModeStorageProvider.overrideWithValue(ThemeModeStorage(preferences)),
      recentSearchesStorageProvider.overrideWithValue(RecentSearchesStorage(preferences)),
      ...crossFeatureOverrides(),
    ],
  );
  unawaited(wakeUpBackend(container.read(apiClientProvider)));

  runApp(UncontrolledProviderScope(container: container, child: const FluwApp()));
}
