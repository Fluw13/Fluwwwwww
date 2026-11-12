import 'dart:io';

import 'package:flutter/services.dart';
import 'package:fluw/core/theme/app_typography.dart';

const Map<String, List<String>> _fontFiles = {
  AppFonts.body: ['Regular', 'Medium', 'SemiBold', 'Bold'],
  AppFonts.heading: ['SemiBold'],
};

/// The default test font has square glyphs, so layout checks at large text sizes need the real font metrics.
Future<void> loadAppFonts() async {
  for (final MapEntry(key: family, value: styles) in _fontFiles.entries) {
    final loader = FontLoader(family);
    for (final style in styles) {
      final bytes = File('assets/fonts/$family-$style.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}
