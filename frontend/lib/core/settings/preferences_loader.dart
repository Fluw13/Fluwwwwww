import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

const Duration _loadTimeout = Duration(seconds: 2);

/// Settings are optional: when storage is slow or broken the app still starts with default settings.
/// main() awaits this before runApp, so any failure from the plugin, Error included, must not block startup.
Future<SharedPreferences?> loadPreferences({Duration timeout = _loadTimeout}) async {
  try {
    return await SharedPreferences.getInstance().timeout(timeout);
  } on Object {
    return null;
  }
}
