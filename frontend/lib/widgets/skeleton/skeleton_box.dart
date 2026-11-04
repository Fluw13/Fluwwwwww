import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';
import 'shimmer_scope.dart';

/// A placeholder block shown in place of content that is still loading.
/// Without a [ShimmerScope] ancestor it renders as a static block.
/// A null [width] fills the available width.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.sm}) : _isTextLine = false;

  const SkeletonBox.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = AppRadius.pill,
      _isTextLine = false;

  /// Takes the same height as one line of text at [fontSize] and grows with the
  /// system text size, so the skeleton keeps the shape of the real text.
  const SkeletonBox.text({super.key, this.width, required double fontSize, double lineHeight = 1.3})
    : height = fontSize * lineHeight,
      radius = 6,
      _isTextLine = true;

  static const double _textBarFactor = 0.7;

  final double? width;
  final double height;
  final double radius;
  final bool _isTextLine;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final Animation<double>? shimmer = ShimmerScope.maybeOf(context);
    final double outerHeight = _isTextLine ? MediaQuery.textScalerOf(context).scale(height) : height;
    final double barHeight = _isTextLine ? outerHeight * _textBarFactor : outerHeight;

    Widget buildBox(double progress) {
      return SizedBox(
        width: width ?? double.infinity,
        height: outerHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: width ?? double.infinity,
            height: barHeight,
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
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: shimmer == null
          ? buildBox(0)
          : AnimatedBuilder(animation: shimmer, builder: (context, _) => buildBox(shimmer.value)),
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
