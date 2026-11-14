import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/features/search/domain/food_item.dart';

sealed class AllergenCheck {
  const AllergenCheck();
}

/// The source has no allergen data (USDA, or a search result before the full product is loaded).
final class AllergensUnknown extends AllergenCheck {
  const AllergensUnknown();
}

/// None of the user's allergens is in the recorded list. Recorded lists can be incomplete, so this is not "safe".
final class NoListedAllergenMatch extends AllergenCheck {
  const NoListedAllergenMatch({required this.recordedTagCount});

  final int recordedTagCount;
}

final class AllergenMatch extends AllergenCheck {
  AllergenMatch({required Set<String> severe, required Set<String> mild})
    : severe = Set.unmodifiable(severe),
      mild = Set.unmodifiable(mild);

  final Set<String> severe;
  final Set<String> mild;
}

AllergenCheck checkAllergens(FoodItem item, PersonalLimits limits) {
  final tags = item.allergenTags;
  if (tags == null) {
    return const AllergensUnknown();
  }
  final severe = limits.severeAllergenTags.intersection(tags.toSet());
  final mild = limits.mildAllergenTags.intersection(tags.toSet());
  if (severe.isEmpty && mild.isEmpty) {
    return NoListedAllergenMatch(recordedTagCount: tags.length);
  }
  return AllergenMatch(severe: severe, mild: mild);
}

/// Share of a daily limit taken by one portion, e.g. 0.42 for 42%. Null when the food or the profile lacks the
/// number, so the UI never shows a share computed from a guess.
final class PortionShare {
  const PortionShare({required this.nutrient, required this.amount, required this.dailyLimit, required this.isWatched});

  final Nutrient nutrient;
  final double amount;
  final double dailyLimit;

  /// The user's condition makes this nutrient important (diabetes → sugar, high blood pressure → sodium...).
  final bool isWatched;

  double get share => amount / dailyLimit;
}

List<PortionShare> portionShares(Nutrients portion, PersonalLimits limits) {
  final candidates = [
    (Nutrient.energyKcal, limits.dailyKcal, false),
    (Nutrient.sugarsG, limits.sugarsMaxG, limits.watchesSugar),
    (Nutrient.saturatedFatG, limits.saturatedFatMaxG, limits.watchesSaturatedFat),
    (Nutrient.sodiumMg, limits.sodiumMaxMg, limits.watchesSodium),
  ];
  return List.unmodifiable([
    for (final (nutrient, limit, isWatched) in candidates)
      if (portion[nutrient] case final amount? when limit != null && limit > 0)
        PortionShare(nutrient: nutrient, amount: amount, dailyLimit: limit, isWatched: isWatched),
  ]);
}
