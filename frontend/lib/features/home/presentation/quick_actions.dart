import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_header.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({required this.onOpenScan, required this.onOpenSearch, super.key});

  final VoidCallback onOpenScan;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Lối tắt'),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.qr_code_scanner,
                  overline: 'Camera',
                  label: 'Quét mã vạch',
                  background: scheme.primary,
                  foreground: scheme.onPrimary,
                  iconBackground: scheme.onPrimary.withValues(alpha: 0.2),
                  iconColor: scheme.onPrimary,
                  onTap: onOpenScan,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionTile(
                  icon: Icons.search,
                  overline: 'Tìm theo tên',
                  label: 'Tra cứu thực phẩm',
                  background: scheme.surfaceContainerLowest,
                  foreground: scheme.onSurface,
                  iconBackground: scheme.tertiaryContainer,
                  iconColor: scheme.onTertiaryContainer,
                  onTap: onOpenSearch,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.overline,
    required this.label,
    required this.background,
    required this.foreground,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String overline;
  final String label;
  final Color background;
  final Color foreground;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(AppRadius.inner);

    return Semantics(
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 1), blurRadius: 2),
          ],
        ),
        child: Material(
          color: background,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: iconBackground),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    overline.toUpperCase(),
                    semanticsLabel: overline,
                    style: theme.textTheme.labelSmall?.copyWith(color: foreground.withValues(alpha: 0.85)),
                  ),
                  Text(label, style: theme.textTheme.titleMedium?.copyWith(color: foreground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
