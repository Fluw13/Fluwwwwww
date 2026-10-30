import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class ScoreColors {
  const ScoreColors({
    required this.ring,
    required this.text,
    required this.container,
  });

  final Color ring;
  final Color text;
  final Color container;

  static ScoreColors lerp(ScoreColors a, ScoreColors b, double t) {
    return ScoreColors(
      ring: Color.lerp(a.ring, b.ring, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      container: Color.lerp(a.container, b.container, t)!,
    );
  }
}
