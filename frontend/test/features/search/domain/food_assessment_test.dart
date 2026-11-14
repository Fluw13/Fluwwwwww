import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/features/search/data/food_item_json.dart';
import 'package:fluw/features/search/domain/food_assessment.dart';

import '../../../fixtures/food_api_samples.dart';

PersonalLimits _limits({
  Set<String> severe = const {},
  Set<String> mild = const {},
  double? dailyKcal = 2000,
  double? sugarsMaxG = 50,
  bool watchesSugar = false,
}) => PersonalLimits(
  profileStatus: ProfileStatus.loaded,
  severeAllergenTags: severe,
  mildAllergenTags: mild,
  allergenNames: const {},
  dailyKcal: dailyKcal,
  proteinMinG: 100,
  sugarsMaxG: sugarsMaxG,
  saturatedFatMaxG: 20,
  sodiumMaxMg: 2000,
  watchesSugar: watchesSugar,
  watchesSodium: false,
  watchesSaturatedFat: false,
);

void main() {
  final product = foodItemFromJson(yoghurtProduct)!;

  test('dị ứng: chưa biết / có ghi nhưng không trùng / danh sách rỗng / trùng nặng và nhẹ', () {
    expect(checkAllergens(foodItemFromJson(yoghurtSearchItem)!, _limits(severe: {'en:milk'})), isA<AllergensUnknown>());
    expect(
      checkAllergens(product, _limits(severe: {'en:peanuts'})),
      isA<NoListedAllergenMatch>().having((check) => check.recordedTagCount, 'count', 1),
    );
    expect(
      checkAllergens(foodItemFromJson(colaItem)!, _limits(severe: {'en:milk'})),
      isA<NoListedAllergenMatch>().having((check) => check.recordedTagCount, 'count', 0),
    );
    final match = checkAllergens(product, _limits(severe: {'en:milk'}, mild: {'en:eggs'})) as AllergenMatch;
    expect(match.severe, {'en:milk'});
    expect(match.mild, isEmpty);
    expect((checkAllergens(product, _limits(mild: {'en:milk'})) as AllergenMatch).mild, {'en:milk'});
  });

  test('phần trăm chỉ tiêu cả ngày cho khẩu phần 200 g sữa chua', () {
    final shares = portionShares(product.facts.forQuantity(200), _limits(watchesSugar: true));
    final byNutrient = {for (final share in shares) share.nutrient: share};

    expect(byNutrient[Nutrient.energyKcal]!.share, closeTo(198.8 / 2000, 1e-9));
    expect(byNutrient[Nutrient.sugarsG]!.share, closeTo(29.4 / 50, 1e-9));
    expect(byNutrient[Nutrient.sugarsG]!.isWatched, isTrue);
    expect(byNutrient[Nutrient.sodiumMg]!.amount, closeTo(72, 1e-9));
    expect(byNutrient.containsKey(Nutrient.saturatedFatG), isFalse, reason: 'món không có số béo bão hòa');
  });

  test('hồ sơ không có chỉ tiêu (chưa có hồ sơ, dưới 18 tuổi) thì không tính phần trăm', () {
    expect(portionShares(product.facts.forQuantity(100), PersonalLimits.none), isEmpty);
    expect(
      portionShares(product.facts.forQuantity(100), _limits(dailyKcal: null, sugarsMaxG: null)).map((s) => s.nutrient),
      [Nutrient.sodiumMg],
    );
  });
}
