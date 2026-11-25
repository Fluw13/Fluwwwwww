import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// Two tiles per row like the design, each row as tall as its taller tile, or one per row when the space is too
/// narrow for two to stay readable.
class TileGrid extends StatelessWidget {
  const TileGrid({required this.children, super.key});

  static const double _minTwoColumnWidth = 320;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _minTwoColumnWidth) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.sm, children: children);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            for (var index = 0; index < children.length; index += 2)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(child: children[index]),
                    Expanded(child: index + 1 < children.length ? children[index + 1] : const SizedBox.shrink()),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
