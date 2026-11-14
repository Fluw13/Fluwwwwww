import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/nutrient_targets.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

/// Lives in `app/` because it joins two features: search reads limits, profile owns the formulas.
/// Daily limits exist only for valid adult profiles; allergens always apply.
PersonalLimits personalLimitsFromProfile(HealthProfile profile, {required CalendarDate today}) {
  Set<String> tagsWith(AllergySeverity severity) => {
    for (final MapEntry(key: allergen, value: level) in profile.dietary.allergies.entries)
      if (level == severity) allergen.openFoodFactsTag,
  };
  final adult = switch (calculateDailyTargets(profile, today: today)) {
    final AdultTargets targets => targets,
    _ => null,
  };

  return PersonalLimits(
    severeAllergenTags: tagsWith(AllergySeverity.severe),
    mildAllergenTags: tagsWith(AllergySeverity.mild),
    allergenNames: {
      for (final allergen in profile.dietary.allergies.keys) allergen.openFoodFactsTag: allergenLabel(allergen),
    },
    dailyKcal: adult?.calories.kcal,
    sugarsMaxG: adult?.nutrients.sugarsMaxGrams,
    saturatedFatMaxG: adult?.nutrients.saturatedFatMaxGrams,
    sodiumMaxMg: adult == null ? null : dailySodiumMaxMg,
    watchesSugar: profile.limitsSugar || profile.conditions.contains(HealthCondition.diabetes),
    watchesSodium: profile.conditions.contains(HealthCondition.hypertension),
    watchesSaturatedFat: profile.conditions.contains(HealthCondition.dyslipidemia),
  );
}
