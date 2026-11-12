import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// Two tiles per row like the design, or one per row when the space is too narrow for two to stay readable.
class TileGrid extends StatelessWidget {
  const TileGrid({required this.children, super.key});

  static const double _minTwoColumnWidth = 320;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= _minTwoColumnWidth ? 2 : 1;
        final tileWidth = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final child in children) SizedBox(width: tileWidth, child: child)],
        );
      },
    );
  }
}
