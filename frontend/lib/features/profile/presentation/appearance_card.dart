import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/presentation/segmented_pills.dart';

/// Lets the user go back to following the phone's light/dark setting after using the header toggle.
class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});

  static const Map<ThemeMode, String> _labels = {
    ThemeMode.system: 'Theo máy',
    ThemeMode.light: 'Sáng',
    ThemeMode.dark: 'Tối',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: 'Giao diện',
      icon: Icons.palette_outlined,
      children: [
        SegmentedPills<ThemeMode>(
          options: _labels,
          selected: ref.watch(themeModeProvider),
          onSelected: ref.read(themeModeProvider.notifier).select,
        ),
      ],
    );
  }
}
