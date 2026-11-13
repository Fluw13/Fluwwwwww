import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/features/profile/data/profile_storage_keys.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';

List<ProfileAllergiesCompanion> allergiesToRows(DietaryPreferences dietary) => [
  for (final MapEntry(key: allergen, value: severity) in dietary.allergies.entries)
    ProfileAllergiesCompanion.insert(allergenKey: allergenKeys[allergen]!, severityKey: allergySeverityKeys[severity]!),
];

List<ProfilePreferencesCompanion> preferencesToRows(DietaryPreferences dietary) => [
  for (final preference in dietary.preferences)
    ProfilePreferencesCompanion.insert(preferenceKey: foodPreferenceKeys[preference]!),
];

/// Returns `null` when an allergen key is unknown (written by a newer version): silently dropping an allergy would
/// switch off its warnings, so the profile is reported as unreadable and the user enters it again.
/// An unknown severity reads as severe, the safer side. Unknown diet styles and habits only affect suggestions, so
/// they fall back to regular and are skipped.
DietaryPreferences? dietaryFromRows({
  required String? dietStyleKey,
  required String? allergyNote,
  required Iterable<ProfileAllergyRow> allergyRows,
  required Iterable<String> preferenceKeys,
}) {
  final allergies = <Allergen, AllergySeverity>{};
  for (final row in allergyRows) {
    final allergen = valueForKey(allergenKeys, row.allergenKey);
    if (allergen == null) {
      return null;
    }
    allergies[allergen] = valueForKey(allergySeverityKeys, row.severityKey) ?? AllergySeverity.severe;
  }

  return DietaryPreferences(
    allergies: allergies,
    allergyNote: allergyNote,
    dietStyle: switch (dietStyleKey) {
      final key? => valueForKey(dietStyleKeys, key) ?? DietStyle.regular,
      null => DietStyle.regular,
    },
    preferences: {for (final key in preferenceKeys) ?valueForKey(foodPreferenceKeys, key)},
  );
}
