import 'package:collection/collection.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';

/// Allergies, eating style and habits. Kept apart from body measurements because none of it feeds the energy
/// formulas; allergies only drive warnings on foods.
final class DietaryPreferences {
  DietaryPreferences({
    required Map<Allergen, AllergySeverity> allergies,
    required this.allergyNote,
    required this.dietStyle,
    required Set<FoodPreference> preferences,
  }) : allergies = Map.unmodifiable(allergies),
       preferences = Set.unmodifiable(preferences);

  DietaryPreferences.none()
    : this(allergies: const {}, allergyNote: null, dietStyle: DietStyle.regular, preferences: const {});

  final Map<Allergen, AllergySeverity> allergies;

  /// Allergies outside the 14 groups; a note only, because free text cannot be matched against product tags.
  final String? allergyNote;

  final DietStyle dietStyle;
  final Set<FoodPreference> preferences;

  @override
  bool operator ==(Object other) =>
      other is DietaryPreferences &&
      const MapEquality<Allergen, AllergySeverity>().equals(other.allergies, allergies) &&
      other.allergyNote == allergyNote &&
      other.dietStyle == dietStyle &&
      const SetEquality<FoodPreference>().equals(other.preferences, preferences);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(allergies.entries.map((entry) => Object.hash(entry.key, entry.value))),
    allergyNote,
    dietStyle,
    Object.hashAllUnordered(preferences),
  );
}
