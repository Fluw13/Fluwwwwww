import 'package:flutter/material.dart';

import '../../core/settings/theme_mode_controller.dart';
import '../../core/settings/theme_mode_scope.dart';

/// Theo máy / Sáng / Tối. The choice applies at once and is kept on the device.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeModeController controller = ThemeModeScope.of(context);

    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: const [
        ButtonSegment(value: ThemeMode.system, label: Text('Theo máy')),
        ButtonSegment(value: ThemeMode.light, label: Text('Sáng')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Tối')),
      ],
      selected: {controller.mode},
      onSelectionChanged: (selection) => controller.setMode(selection.single),
    );
  }
}
