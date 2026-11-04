import 'package:flutter/material.dart';

import 'core/licenses/font_licenses.dart';
import 'core/settings/shared_prefs_theme_mode_store.dart';
import 'core/settings/theme_mode_controller.dart';
import 'core/settings/theme_mode_scope.dart';
import 'core/theme/app_theme.dart';
import 'data/api/fluw_api_client.dart';
import 'data/api/fluw_api_scope.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();

  final ThemeModeController themeModeController = ThemeModeController(
    SharedPrefsThemeModeStore(),
  );
  await themeModeController.load();

  runApp(
    FluwApp(
      themeModeController: themeModeController,
      apiClient: FluwApiClient(),
    ),
  );
}

class FluwApp extends StatelessWidget {
  const FluwApp({
    super.key,
    required this.themeModeController,
    required this.apiClient,
    this.home,
  });

  final ThemeModeController themeModeController;
  final FluwApiClient apiClient;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return FluwApiScope(
      client: apiClient,
      child: ThemeModeScope(
        controller: themeModeController,
        child: ListenableBuilder(
          listenable: themeModeController,
          builder: (context, _) => MaterialApp(
            title: 'Fluw',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeModeController.mode,
            home: home ?? const HomeScreen(),
          ),
        ),
      ),
    );
  }
}
