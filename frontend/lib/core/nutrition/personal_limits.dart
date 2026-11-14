/// What the user's profile says about foods, in a form any feature can use without importing the profile feature.
/// Built in `app/` from the stored profile. A null limit means there is no target for it (no profile, under 18).
final class PersonalLimits {
  const PersonalLimits({
    required this.severeAllergenTags,
    required this.mildAllergenTags,
    required this.allergenNames,
    required this.dailyKcal,
    required this.sugarsMaxG,
    required this.saturatedFatMaxG,
    required this.sodiumMaxMg,
    required this.watchesSugar,
    required this.watchesSodium,
    required this.watchesSaturatedFat,
  });

  static const PersonalLimits none = PersonalLimits(
    severeAllergenTags: {},
    mildAllergenTags: {},
    allergenNames: {},
    dailyKcal: null,
    sugarsMaxG: null,
    saturatedFatMaxG: null,
    sodiumMaxMg: null,
    watchesSugar: false,
    watchesSodium: false,
    watchesSaturatedFat: false,
  );

  /// Open Food Facts allergen tags, e.g. `en:milk`.
  final Set<String> severeAllergenTags;
  final Set<String> mildAllergenTags;

  /// How the user named each of their allergen tags in the profile, for warnings in their own words.
  final Map<String, String> allergenNames;

  final double? dailyKcal;
  final double? sugarsMaxG;
  final double? saturatedFatMaxG;
  final double? sodiumMaxMg;

  /// Diabetes or "giảm ngọt": sugar is highlighted.
  final bool watchesSugar;

  /// High blood pressure: sodium is highlighted.
  final bool watchesSodium;

  /// High blood lipids: saturated fat is highlighted.
  final bool watchesSaturatedFat;
}
