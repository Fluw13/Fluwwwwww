import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/app/app_router.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class FluwApp extends ConsumerStatefulWidget {
  const FluwApp({super.key});

  @override
  ConsumerState<FluwApp> createState() => _FluwAppState();
}

class _FluwAppState extends ConsumerState<FluwApp> {
  final GoRouter _router = createAppRouter();

  @override
  void dispose() {
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
      routerConfig: _router,
    );
  }
}
