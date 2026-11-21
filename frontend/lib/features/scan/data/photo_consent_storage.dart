import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user agreed to send food photos to Google Gemini through the Fluw server. Without a store, or on any
/// error, the answer is "not yet", so the app asks again rather than send a photo without consent.
class PhotoConsentStorage {
  const PhotoConsentStorage(this._preferences);

  /// The version of the consent text the user agreed to.
  static const String key = 'photo_recognition_consent_version';

  /// Raised whenever the consent text changes in substance, so everyone is asked again with the new text. Version 2
  /// added the server's country, that Google keeps photos sent before a withdrawal, and the policy.
  static const int currentVersion = 2;

  /// Version 1 stored `true` here; it no longer counts as consent.
  static const String legacyKey = 'photo_recognition_consent';

  final SharedPreferences? _preferences;

  bool get hasConsent {
    try {
      return _preferences?.getInt(key) == currentVersion;
    } on Object {
      return false;
    }
  }

  Future<void> giveConsent() async {
    try {
      await _preferences?.setInt(key, currentVersion);
      await _preferences?.remove(legacyKey);
    } on Object {
      // Asked again next time.
    }
  }

  /// Withdrawing is as easy as giving: the next photo asks again.
  Future<void> withdrawConsent() async {
    try {
      await _preferences?.remove(key);
      await _preferences?.remove(legacyKey);
    } on Object {
      // Still recorded as given; the user can withdraw again.
    }
  }
}

final photoConsentStorageProvider = Provider<PhotoConsentStorage>(
  (ref) => throw UnimplementedError('photoConsentStorageProvider phải được nối trong main()'),
);
