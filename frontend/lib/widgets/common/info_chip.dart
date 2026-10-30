import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

/// A small rounded label, e.g. a score level or the "Do AI tạo" marker.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.emphasized = false,
  });

  static const double verticalPadding = 5;
  static const double lineHeight = 1.3;
  static const double fontSize = 12;
  static const double emphasizedFontSize = 15;

  final String label;
  final Color foreground;
  final Color background;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: emphasized ? 14 : 10, vertical: verticalPadding),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: emphasized ? emphasizedFontSize : fontSize,
          height: lineHeight,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
