import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/licenses/data_licenses.dart';

void main() {
  test('trang giấy phép có nguồn và giấy phép dữ liệu của Open Food Facts và USDA', () async {
    registerDataLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    String textOf(String package) => entries
        .where((entry) => entry.packages.contains(package))
        .expand((entry) => entry.paragraphs)
        .map((paragraph) => paragraph.text)
        .join(' ');

    expect(textOf('Open Food Facts'), allOf(contains('ODbL'), contains('CC BY-SA')));
    expect(textOf('USDA FoodData Central'), contains('CC0'));
  });
}
