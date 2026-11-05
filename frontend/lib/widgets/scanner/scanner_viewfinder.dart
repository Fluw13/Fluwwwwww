import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dims the camera outside the scan window and draws its corner brackets and
/// a moving scan line. The screen computes the window once with [windowFor]
/// and gives the same rect to the scanner, so only codes inside the frame are read.
class ScannerViewfinder extends StatefulWidget {
  const ScannerViewfinder({super.key, required this.window, this.animating = true});

  static const Size windowSize = Size(300, 160);
  static const double windowRadius = 20;
  static const double minSideMargin = 24;
  static const double maxHeightFraction = 0.3;

  /// Same in both themes: the viewfinder always sits on a dark camera preview.
  static const Color lineColor = Color(0xFF00E676);

  final Rect window;

  /// False once a code has been read, so the line stops instead of suggesting
  /// the camera is still looking.
  final bool animating;

  static Rect windowFor(Size area) {
    final double width = math.min(windowSize.width, math.max(0.0, area.width - minSideMargin * 2));
    return Rect.fromCenter(
      center: Offset(area.width / 2, area.height * 0.42),
      width: width,
      height: math.min(windowSize.height, area.height * maxHeightFraction),
    );
  }

  @override
  State<ScannerViewfinder> createState() => _ScannerViewfinderState();
}

class _ScannerViewfinderState extends State<ScannerViewfinder> with SingleTickerProviderStateMixin {
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(ScannerViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animating != widget.animating) _syncAnimation();
  }

  void _syncAnimation() {
    if (!widget.animating || MediaQuery.disableAnimationsOf(context)) {
      _line
        ..stop()
        ..value = 0.5;
    } else if (!_line.isAnimating) {
      _line.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _line,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ViewfinderPainter(window: widget.window, lineProgress: _line.value),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({required this.window, required this.lineProgress});

  static const double _cornerLength = 34;
  static const double _cornerStroke = 4;
  static const double _lineInset = 18;

  final Rect window;
  final double lineProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect frame = RRect.fromRectAndRadius(window, const Radius.circular(ScannerViewfinder.windowRadius));

    final Path dimmed = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(frame),
    );
    canvas.drawPath(dimmed, Paint()..color = const Color(0x8C000000));

    _paintCorners(canvas);

    final double y = window.top + _lineInset + (window.height - _lineInset * 2) * lineProgress;
    canvas.drawRRect(
      RRect.fromLTRBR(window.left + _lineInset, y - 1, window.right - _lineInset, y + 1, const Radius.circular(2)),
      Paint()..color = ScannerViewfinder.lineColor,
    );
  }

  void _paintCorners(Canvas canvas) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;
    const double r = ScannerViewfinder.windowRadius;
    final double l = math.min(_cornerLength, window.width / 2);
    final Rect w = window;

    canvas
      ..drawPath(
        Path()
          ..moveTo(w.left, w.top + l)
          ..lineTo(w.left, w.top + r)
          ..arcToPoint(Offset(w.left + r, w.top), radius: const Radius.circular(r))
          ..lineTo(w.left + l, w.top),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w.right - l, w.top)
          ..lineTo(w.right - r, w.top)
          ..arcToPoint(Offset(w.right, w.top + r), radius: const Radius.circular(r))
          ..lineTo(w.right, w.top + l),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w.right, w.bottom - l)
          ..lineTo(w.right, w.bottom - r)
          ..arcToPoint(Offset(w.right - r, w.bottom), radius: const Radius.circular(r))
          ..lineTo(w.right - l, w.bottom),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w.left + l, w.bottom)
          ..lineTo(w.left + r, w.bottom)
          ..arcToPoint(Offset(w.left, w.bottom - r), radius: const Radius.circular(r))
          ..lineTo(w.left, w.bottom - l),
        paint,
      );
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) {
    return oldDelegate.window != window || oldDelegate.lineProgress != lineProgress;
  }
}
