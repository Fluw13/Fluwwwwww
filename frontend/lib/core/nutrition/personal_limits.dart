/// Whether the limits come from a readable profile. Kept so the UI can say "your profile could not be read"
/// instead of silently showing no allergen warnings.
enum ProfileStatus { none, loading, unreadable, loaded }

/// Which kind of daily targets a readable profile gets, so each case is worded on its own: a 16-year-old or a
/// 12-year-old must never be told to fix a profile that is fine.
enum TargetsKind { adult, teen, belowMinimumAge, invalid }

/// What the user's profile says about foods, in a form any feature can use without importing the profile feature.
/// Built in `app/` from the stored profile. A null limit means there is no target for it (no profile, under 18).
final class PersonalLimits {
  const PersonalLimits({
    required this.profileStatus,
    required this.severeAllergenTags,
    required this.mildAllergenTags,
    required this.allergenNames,
    required this.dailyKcal,
    required this.proteinMinG,
    required this.sugarsMaxG,
    required this.saturatedFatMaxG,
    required this.sodiumMaxMg,
    required this.watchesSugar,
    required this.watchesSodium,
    required this.watchesSaturatedFat,
    this.fatTargetG,
    this.carbohydratesTargetG,
    this.displayName,
    this.goalLabel,
    this.avoidsAnimalProducts = false,
    this.limitsCarbohydrates = false,
    this.prefersSteamedOrBoiled = false,
    this.likesNuts = false,
    this.targetsKind,
    this.isAdult = false,
  });

  static const PersonalLimits none = PersonalLimits.empty(ProfileStatus.none);

  /// No allergens and no limits, for every status except [ProfileStatus.loaded].
  const PersonalLimits.empty(ProfileStatus status)
    : this(
        profileStatus: status,
        severeAllergenTags: const {},
        mildAllergenTags: const {},
        allergenNames: const {},
        dailyKcal: null,
        proteinMinG: null,
        sugarsMaxG: null,
        saturatedFatMaxG: null,
        sodiumMaxMg: null,
        watchesSugar: false,
        watchesSodium: false,
        watchesSaturatedFat: false,
      );

  final ProfileStatus profileStatus;

  /// Open Food Facts allergen tags, e.g. `en:milk`.
  final Set<String> severeAllergenTags;
  final Set<String> mildAllergenTags;

  /// How the user named each of their allergen tags in the profile, for warnings in their own words.
  final Map<String, String> allergenNames;

  final double? dailyKcal;

  /// The lower end of the protein range; teens get theirs too, since protein is the one target they have.
  final double? proteinMinG;
  final double? sugarsMaxG;
  final double? saturatedFatMaxG;
  final double? sodiumMaxMg;

  /// Diabetes or "giảm ngọt": sugar is highlighted.
  final bool watchesSugar;

  /// High blood pressure: sodium is highlighted.
  final bool watchesSodium;

  /// High blood lipids: saturated fat is highlighted.
  final bool watchesSaturatedFat;

  /// Daily targets for adults with a valid profile. Carbohydrates is null when it cannot be worked out (the protein
  /// and fat targets already use up the calories), shown as "Chưa tính được".
  final double? fatTargetG;
  final double? carbohydratesTargetG;

  /// Optional name from the profile, for the greeting.
  final String? displayName;

  /// What the targets are planned for, e.g. "Giảm cân".
  final String? goalLabel;

  /// Eating style and habits; they only shape meal suggestions, never a target.
  final bool avoidsAnimalProducts;
  final bool limitsCarbohydrates;
  final bool prefersSteamedOrBoiled;
  final bool likesNuts;

  /// Null unless [profileStatus] is [ProfileStatus.loaded].
  final TargetsKind? targetsKind;

  /// 18 or older by the stored birth date, even when the rest of the profile is incomplete. False without a profile.
  /// Photo recognition is only offered to adults: the Gemini API terms bar services likely used by people under 18.
  final bool isAdult;
}
