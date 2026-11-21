import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/app/app_router.dart';
import 'package:fluw/core/network/backend_warm_up.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/core/time/current_hour_provider.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/reminders/presentation/reminder_sync.dart';
import 'package:go_router/go_router.dart';

class FluwApp extends ConsumerStatefulWidget {
  const FluwApp({super.key});

  @override
  ConsumerState<FluwApp> createState() => _FluwAppState();
}

class _FluwAppState extends ConsumerState<FluwApp> {
  final GoRouter _router = createAppRouter();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _wakeUpBackend();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        // The date only changes while the app is in the background long enough to matter (overnight, birthdays).
        ref.invalidate(todayProvider);
        // Timers stop while the phone sleeps, so the hour would stay at last night's (evening advice in the morning).
        ref.invalidate(currentHourProvider);
        // The free server has gone back to sleep after 15 idle minutes.
        _wakeUpBackend();
      },
    );
  }

  void _wakeUpBackend() => ref.read(backendWarmUpProvider)().ignore();

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fluw',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
      builder: (context, child) => ReminderSync(child: child!),
    );
  }
}
