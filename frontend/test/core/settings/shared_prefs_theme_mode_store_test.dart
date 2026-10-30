import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/settings/shared_prefs_theme_mode_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('chưa có dữ liệu thì trả null', () async {
    expect(await SharedPrefsThemeModeStore().read(), isNull);
  });

  test('ghi rồi đọc lại đúng lựa chọn, kể cả từ một phiên bản store mới (mở lại app)', () async {
    await SharedPrefsThemeModeStore().write(ThemeMode.dark);

    expect(await SharedPrefsThemeModeStore().read(), ThemeMode.dark);
  });

  test('giá trị lạ trong bộ nhớ được bỏ qua', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData(
      {SharedPrefsThemeModeStore.storageKey: 'purple'},
    );

    expect(await SharedPrefsThemeModeStore().read(), isNull);
  });
}
