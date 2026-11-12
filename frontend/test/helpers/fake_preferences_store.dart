import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Replaces the platform store so tests can make loading slow or failing and writes fail.
final class FakePreferencesStore extends SharedPreferencesStorePlatform {
  FakePreferencesStore({Future<Map<String, Object>> Function()? load, this.failWrites = false})
    : _load = load ?? (() async => <String, Object>{});

  final Future<Map<String, Object>> Function() _load;
  final bool failWrites;

  void install() {
    final original = SharedPreferencesStorePlatform.instance;
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = this;
    addTearDown(() {
      SharedPreferencesStorePlatform.instance = original;
      SharedPreferences.resetStatic();
    });
  }

  @override
  Future<Map<String, Object>> getAll() => _load();

  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) => _load();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failWrites) {
      throw PlatformException(code: 'write-failed');
    }
    return true;
  }

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> clear() async => true;
}
