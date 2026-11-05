import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// A small rounded label, e.g. a score level or the "Nội dung do AI tạo" marker.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.emphasized = false,
    this.icon,
  });

  static const double verticalPadding = 5;
  static const double lineHeight = 1.3;
  static const double fontSize = 12;
  static const double emphasizedFontSize = 15;

  final String label;
  final Color foreground;
  final Color background;
  final bool emphasized;

  /// Shown before the label so the meaning never relies on colour alone.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final double size = emphasized ? emphasizedFontSize : fontSize;
    final IconData? icon = this.icon;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: emphasized ? 14 : 10,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: size,
                height: lineHeight,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
