import 'package:flutter/material.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/theme/app_palette.dart';
import 'package:fluw/core/theme/app_spacing.dart';

class FluwBottomBar extends StatelessWidget {
  const FluwBottomBar({required this.currentTab, required this.onSelected, super.key});

  static const double barHeight = 64;
  static const double scanButtonSize = 56;
  static const double _scanButtonRise = 24;
  static const double _maxLabelTextScale = 1.3;

  final AppTab currentTab;
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // The raised scan button must stay inside this widget's bounds to receive taps, so the bar reserves that height.
    // Labels stop growing at 130%, the same limit as Material's NavigationBar, because the bar has a fixed height.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxLabelTextScale,
      child: SizedBox(
        height: _scanButtonRise + barHeight + bottomInset,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight + bottomInset,
              child: Material(
                color: colorScheme.surfaceContainerLowest,
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Row(
                    children: [
                      for (final tab in AppTab.values)
                        Expanded(
                          child: _TabItem(
                            tab: tab,
                            selected: tab == currentTab,
                            showIcon: tab != AppTab.scan,
                            onTap: () => onSelected(tab),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(child: _ScanButton(onTap: () => onSelected(AppTab.scan))),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected, required this.showIcon, required this.onTap});

  final AppTab tab;
  final bool selected;
  final bool showIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showIcon) Icon(selected ? tab.selectedIcon : tab.icon, color: color),
              const SizedBox(height: AppSpacing.xs),
              // Narrow screens: shrink a long label to its slot instead of overflowing.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tab.label, maxLines: 1, style: theme.textTheme.labelMedium?.copyWith(color: color)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // The tab item underneath already announces "Quét Món" to screen readers.
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppPalette.accent.withValues(alpha: 0.35), blurRadius: 16)],
        ),
        child: Material(
          color: colorScheme.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: FluwBottomBar.scanButtonSize,
              child: Icon(AppTab.scan.icon, color: colorScheme.onPrimary, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
