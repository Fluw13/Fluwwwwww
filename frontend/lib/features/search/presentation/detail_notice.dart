import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// One line of warning on the detail screen with its icon, so it never relies on colour alone.
class DetailNotice extends StatelessWidget {
  const DetailNotice({required this.icon, required this.text, required this.color, super.key});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
