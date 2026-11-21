import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/settings/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's consent to keep health data (birth date, body measures, pregnancy, conditions, allergies) on this
/// phone, which Vietnam's personal data law asks for before sensitive data is processed. Recorded with the version of
/// the text and the time, so a changed text asks again. Without a store, or on any error, the answer is "not yet", so
/// the app asks rather than assume.
final class HealthDataConsentStorage {
  const HealthDataConsentStorage(this._preferences);

  static const String versionKey = 'health_data_consent_version';
  static const String agreedAtKey = 'health_data_consent_agreed_at';

  /// Raised whenever the consent text changes in substance, so everyone agrees to the new text.
  static const int currentVersion = 1;

  final SharedPreferences? _preferences;

  bool get hasConsent {
    try {
      return _preferences?.getInt(versionKey) == currentVersion;
    } on Object {
      return false;
    }
  }

  /// The time goes first, so a stored version always comes with its time.
  Future<void> giveConsent(DateTime agreedAt) async {
    try {
      await _preferences?.setString(agreedAtKey, agreedAt.toUtc().toIso8601String());
      await _preferences?.setInt(versionKey, currentVersion);
    } on Object {
      // The user did agree; the question simply comes back at the next save.
    }
  }
}

final healthDataConsentStorageProvider = Provider<HealthDataConsentStorage>(
  (ref) => HealthDataConsentStorage(ref.watch(sharedPreferencesProvider)),
);
