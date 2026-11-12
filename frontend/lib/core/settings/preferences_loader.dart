import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

const Duration _loadTimeout = Duration(seconds: 2);

/// Settings are optional: when storage is slow or broken the app still starts with default settings.
Future<SharedPreferences?> loadPreferences() async {
  try {
    return await SharedPreferences.getInstance().timeout(_loadTimeout);
  } on Exception {
    return null;
  }
}
