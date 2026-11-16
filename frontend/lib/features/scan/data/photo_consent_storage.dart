import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user agreed to send food photos to Google Gemini through the Fluw server. Without a store, or on any
/// error, the answer is "not yet", so the app asks again rather than send a photo without consent.
class PhotoConsentStorage {
  const PhotoConsentStorage(this._preferences);

  static const String key = 'photo_recognition_consent';

  final SharedPreferences? _preferences;

  bool get hasConsent {
    try {
      return _preferences?.getBool(key) ?? false;
    } on Object {
      return false;
    }
  }

  Future<void> giveConsent() async {
    try {
      await _preferences?.setBool(key, true);
    } on Object {
      // Asked again next time.
    }
  }
}

final photoConsentStorageProvider = Provider<PhotoConsentStorage>(
  (ref) => throw UnimplementedError('photoConsentStorageProvider phải được nối trong main()'),
);
