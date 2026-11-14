import 'package:flutter/foundation.dart';

/// Open Food Facts (ODbL, photos CC BY-SA) asks for attribution wherever its data is shown; USDA data is CC0.
/// Listed with the package licenses so every source and license can be read in one place.
void registerDataLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Open Food Facts'],
      'Dữ liệu sản phẩm © các cộng tác viên Open Food Facts, cấp phép theo Open Database License (ODbL) 1.0: '
      'https://opendatacommons.org/licenses/odbl/1-0/\n'
      'Ảnh sản phẩm cấp phép theo Creative Commons Attribution-ShareAlike (CC BY-SA).\n'
      'https://world.openfoodfacts.org',
    );
    yield const LicenseEntryWithLineBreaks(
      ['USDA FoodData Central'],
      'U.S. Department of Agriculture, Agricultural Research Service. FoodData Central. '
      'Dữ liệu thuộc phạm vi công cộng (CC0 1.0).\n'
      'https://fdc.nal.usda.gov',
    );
  });
}
