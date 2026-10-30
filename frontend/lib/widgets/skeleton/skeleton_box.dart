import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';
import 'shimmer_scope.dart';

/// A placeholder block shown in place of content that is still loading.
/// Without a [ShimmerScope] ancestor it renders as a static block.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = AppRadius.pill;

  const SkeletonBox.line({super.key, this.width, this.height = 12}) : radius = 6;

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final Animation<double>? shimmer = ShimmerScope.maybeOf(context);

    Widget buildBox(double progress) {
      return SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [palette.skeletonBase, palette.skeletonHighlight, palette.skeletonBase],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlidingGradientTransform(progress),
            ),
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: shimmer == null
          ? buildBox(0)
          : AnimatedBuilder(
              animation: shimmer,
              builder: (context, _) => buildBox(shimmer.value),
            ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
  }
}
