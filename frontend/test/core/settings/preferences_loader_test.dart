import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/settings/preferences_loader.dart';

import '../../helpers/fake_preferences_store.dart';

void main() {
  test('đọc được thì trả về cài đặt đã lưu', () async {
    FakePreferencesStore(load: () async => {'flutter.theme_mode': 'dark'}).install();

    final preferences = await loadPreferences();

    expect(preferences?.getString('theme_mode'), 'dark');
  });

  test('plugin báo lỗi (Exception) thì trả null để app vẫn mở được', () async {
    FakePreferencesStore(load: () => Future.error(PlatformException(code: 'broken'))).install();

    expect(await loadPreferences(), isNull);
  });

  test('plugin ném Error thì cũng trả null, không chặn app ở màn chờ', () async {
    FakePreferencesStore(load: () => Future.error(StateError('broken'))).install();

    expect(await loadPreferences(), isNull);
  });

  test('đọc quá thời gian chờ thì trả null', () async {
    FakePreferencesStore(load: () => Completer<Map<String, Object>>().future).install();

    expect(await loadPreferences(timeout: const Duration(milliseconds: 20)), isNull);
  });
}
