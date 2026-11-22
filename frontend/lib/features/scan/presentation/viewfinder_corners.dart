import 'package:flutter/material.dart';

/// The design's rounded L-shaped brackets at the four corners of a box, over the camera or the photo area.
class ViewfinderCorners extends StatelessWidget {
  const ViewfinderCorners({required this.color, this.length = 24, this.thickness = 4, super.key});

  final Color color;
  final double length;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornersPainter(color: color, length: length, thickness: thickness),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  const _CornersPainter({required this.color, required this.length, required this.thickness});

  final Color color;
  final double length;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final inset = thickness / 2;
    final (left, top, right, bottom) = (inset, inset, size.width - inset, size.height - inset);
    for (final (x, y, dx, dy) in [
      (left, top, 1, 1),
      (right, top, -1, 1),
      (left, bottom, 1, -1),
      (right, bottom, -1, -1),
    ]) {
      canvas
        ..drawLine(Offset(x, y), Offset(x + dx * length, y), paint)
        ..drawLine(Offset(x, y), Offset(x, y + dy * length), paint);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.length != length || oldDelegate.thickness != thickness;
}
