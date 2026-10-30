import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/settings/theme_mode_controller.dart';
import 'package:frontend/core/settings/theme_mode_scope.dart';
import 'package:frontend/core/settings/theme_mode_store.dart';
import 'package:frontend/core/theme/fluw_palette.dart';
import 'package:frontend/main.dart';

class _MemoryStore implements ThemeModeStore {
  ThemeMode? value;

  @override
  Future<ThemeMode?> read() async => value;

  @override
  Future<void> write(ThemeMode mode) async => value = mode;
}

class _Probe extends StatelessWidget {
  const _Probe({required this.onBuild});

  final ValueChanged<BuildContext> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return Scaffold(appBar: AppBar(title: const Text('Fluw')));
  }
}

SystemUiOverlayStyle _statusBarStyle(WidgetTester tester) {
  return tester
      .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(of: find.byType(AppBar), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
      )
      .value;
}

void main() {
  testWidgets('FluwApp đổi sáng/tối theo lựa chọn và giữ lựa chọn sau khi mở lại', (tester) async {
    final _MemoryStore store = _MemoryStore();
    final ThemeModeController controller = ThemeModeController(store);
    addTearDown(controller.dispose);
    await controller.load();

    late BuildContext probe;
    await tester.pumpWidget(
      FluwApp(themeModeController: controller, home: _Probe(onBuild: (context) => probe = context)),
    );

    await ThemeModeScope.of(probe).setMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(Theme.of(probe).brightness, Brightness.dark);
    expect(probe.palette.background, FluwPalette.dark.background);
    expect(_statusBarStyle(tester).statusBarIconBrightness, Brightness.light);

    final ThemeModeController reopened = ThemeModeController(store);
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.mode, ThemeMode.dark);

    await controller.setMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(Theme.of(probe).brightness, Brightness.light);
    expect(_statusBarStyle(tester).statusBarIconBrightness, Brightness.dark);
  });

  testWidgets('chế độ "Theo máy" đi theo độ sáng của điện thoại', (tester) async {
    final ThemeModeController controller = ThemeModeController(_MemoryStore());
    addTearDown(controller.dispose);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    late BuildContext probe;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(
      FluwApp(themeModeController: controller, home: _Probe(onBuild: (context) => probe = context)),
    );
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.system);
    expect(Theme.of(probe).brightness, Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(Theme.of(probe).brightness, Brightness.light);
  });
}
