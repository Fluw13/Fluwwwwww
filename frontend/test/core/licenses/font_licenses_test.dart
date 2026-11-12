import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/licenses/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('đăng ký giấy phép OFL cho cả hai phông đi kèm app', () async {
    registerFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final fontEntries = entries.where((entry) => entry.packages.any(['Inter', 'Plus Jakarta Sans'].contains)).toList();

    expect(fontEntries.expand((entry) => entry.packages), containsAll(['Inter', 'Plus Jakarta Sans']));
    for (final entry in fontEntries) {
      final text = entry.paragraphs.map((paragraph) => paragraph.text).join(' ');
      expect(text, contains('SIL Open Font License'));
    }
  });
}
