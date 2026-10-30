import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The SIL Open Font License requires the licence text to ship with the font,
/// so it is listed on Flutter's licence page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(_beVietnamProLicense);
}

Stream<LicenseEntry> _beVietnamProLicense() async* {
  final String text = await rootBundle.loadString('assets/fonts/BeVietnamPro/OFL.txt');
  yield LicenseEntryWithLineBreaks(const ['Be Vietnam Pro'], text);
}
