import 'dart:math';

import 'package:flutter/painting.dart';

/// [color] darkened (on a light [background]) or lightened (on a dark one) until text in it reaches [minContrast],
/// WCAG AA by default. Lets a chart colour such as #10B981, too light for text, label its own number in a darker
/// shade of the same hue.
Color readableOn(Color color, Color background, {double minContrast = 4.5}) {
  final darken = background.computeLuminance() > 0.5;
  var hsl = HSLColor.fromColor(color);
  while (contrastRatio(hsl.toColor(), background) < minContrast) {
    final lightness = hsl.lightness + (darken ? -0.02 : 0.02);
    if (lightness <= 0 || lightness >= 1) {
      return darken ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    }
    hsl = hsl.withLightness(lightness);
  }
  return hsl.toColor();
}

double contrastRatio(Color first, Color second) {
  final lighter = max(first.computeLuminance(), second.computeLuminance());
  final darker = min(first.computeLuminance(), second.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}
