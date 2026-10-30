import 'package:flutter/widgets.dart';

import 'theme_mode_controller.dart';

class ThemeModeScope extends InheritedNotifier<ThemeModeController> {
  const ThemeModeScope({
    super.key,
    required ThemeModeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeModeController of(BuildContext context) {
    final ThemeModeScope? scope = context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    assert(scope != null, 'ThemeModeScope.of() called without a ThemeModeScope ancestor.');
    return scope!.notifier!;
  }
}
