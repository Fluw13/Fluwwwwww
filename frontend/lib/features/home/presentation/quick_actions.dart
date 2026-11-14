import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';

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
        Semantics(header: true, child: Text('Lối tắt', style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.qr_code_scanner,
                label: 'Quét mã vạch',
                background: scheme.primary,
                foreground: scheme.onPrimary,
                onTap: onOpenScan,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionTile(
                icon: Icons.search,
                label: 'Tra cứu thực phẩm',
                background: scheme.surfaceContainerLowest,
                foreground: scheme.onSurface,
                onTap: onOpenSearch,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground, size: 28),
              const SizedBox(height: AppSpacing.md),
              Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
