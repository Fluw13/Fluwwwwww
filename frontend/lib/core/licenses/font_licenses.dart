import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const Map<String, String> _fontLicenseAssets = {
  'Inter': 'assets/licenses/Inter-OFL.txt',
  'Plus Jakarta Sans': 'assets/licenses/PlusJakartaSans-OFL.txt',
};

/// The SIL Open Font License requires shipping its text with the bundled fonts.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: asset) in _fontLicenseAssets.entries) {
      yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString(asset));
    }
  });
}
