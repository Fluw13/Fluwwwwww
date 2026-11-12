import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/settings/theme_mode_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_preferences_store.dart';

void main() {
  test('ghi bị lỗi thì bỏ qua, không làm hỏng thao tác đổi giao diện', () async {
    FakePreferencesStore(failWrites: true).install();
    final storage = ThemeModeStorage(await SharedPreferences.getInstance());

    await expectLater(storage.write(ThemeMode.dark), completes);
  });

  test('không đọc được cài đặt thì theo máy, ghi không làm gì', () async {
    const storage = ThemeModeStorage(null);

    expect(storage.read(), ThemeMode.system);
    await expectLater(storage.write(ThemeMode.dark), completes);
  });

  test('đọc đúng cả 3 lựa chọn đã lưu', () async {
    for (final mode in ThemeMode.values) {
      SharedPreferences.setMockInitialValues({'theme_mode': mode.name});
      final storage = ThemeModeStorage(await SharedPreferences.getInstance());

      expect(storage.read(), mode);
    }
  });
}
