import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// The design's pill switch between barcode and photo. The chosen side takes the primary fill (white on #10B981, as
/// drawn, is below the contrast minimum).
class ScanModeSwitch extends StatelessWidget {
  const ScanModeSwitch({required this.photoMode, required this.onChanged, super.key});

  final bool photoMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(color: scheme.surfaceContainerHigh, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: _Segment(
                icon: Icons.qr_code_scanner,
                label: 'Mã vạch',
                isSelected: !photoMode,
                onTap: () => onChanged(false),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Segment(
                icon: Icons.photo_camera_outlined,
                label: 'Ảnh món ăn',
                isSelected: photoMode,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.icon, required this.label, required this.isSelected, required this.onTap});

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            // 48 dp: the minimum touch target.
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
