import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingIcon = Icons.chevron_right,
    this.tapHint,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData trailingIcon;
  final VoidCallback onTap;

  /// Read by screen readers as what a tap does, when it is not "open".
  final String? tapHint;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? subtitle = this.subtitle;

    return Semantics(
      button: true,
      onTapHint: tapHint,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 22, color: palette.textPrimary),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w500)),
                      if (subtitle != null)
                        Text(subtitle, style: TextStyle(fontSize: 13, height: 1.35, color: palette.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(child: Icon(trailingIcon, size: 20, color: palette.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
