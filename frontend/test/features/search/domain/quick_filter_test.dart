import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/search/data/food_item_json.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/quick_filter.dart';

import '../../../fixtures/food_api_samples.dart';

FoodItem _food(Map<String, Object?> nutrients, {String unit = 'g'}) => foodItemFromJson({
  ...colaItem,
  'basis': {'amount': 100, 'unit': unit},
  'nutrients': nutrients,
})!;

void main() {
  final yoghurt = foodItemFromJson(yoghurtSearchItem)!;
  final cola = foodItemFromJson(colaItem)!;
  final chicken = foodItemFromJson(chickenItem)!;
  final noData = foodItemFromJson({...colaItem, 'nutrients': <String, Object?>{}})!;

  test('đường ≤ 5 g, protein ≥ 20 g, dưới 200 kcal (theo 100 g/ml)', () {
    expect(applyQuickFilters([yoghurt, cola, chicken], {QuickFilter.lowSugar}), [chicken]);
    expect(applyQuickFilters([yoghurt, cola, chicken], {QuickFilter.highProtein}), [chicken]);
    expect(applyQuickFilters([yoghurt, cola, chicken], {QuickFilter.under200Kcal}), [yoghurt, cola, chicken]);
  });

  test('nhiều bộ lọc thì phải đạt tất cả; không có bộ lọc thì giữ nguyên', () {
    expect(applyQuickFilters([yoghurt, chicken], {QuickFilter.lowSugar, QuickFilter.highProtein}), [chicken]);
    expect(applyQuickFilters([yoghurt, chicken], {}), [yoghurt, chicken]);
  });

  test('thiếu số liệu thì không bao giờ đạt bộ lọc', () {
    for (final filter in QuickFilter.values) {
      expect(filter.matches(noData), isFalse, reason: '$filter');
    }
  });

  test('đúng ngưỡng: đường 5 g và protein 20 g đạt, 200 kcal thì không (dưới 200)', () {
    final exactly = _food({'sugarsG': 5, 'proteinG': 20, 'energyKcal': 200});
    final over = _food({'sugarsG': 5.01, 'proteinG': 19.99, 'energyKcal': 199.9});

    expect(QuickFilter.lowSugar.matches(exactly), isTrue);
    expect(QuickFilter.highProtein.matches(exactly), isTrue);
    expect(QuickFilter.under200Kcal.matches(exactly), isFalse);
    expect(QuickFilter.lowSugar.matches(over), isFalse);
    expect(QuickFilter.highProtein.matches(over), isFalse);
    expect(QuickFilter.under200Kcal.matches(over), isTrue);
  });

  test('đồ uống (theo 100 ml): ít đường là ≤ 2,5 g, không phải 5 g', () {
    expect(QuickFilter.lowSugar.matches(_food({'sugarsG': 2.5}, unit: 'ml')), isTrue);
    expect(QuickFilter.lowSugar.matches(_food({'sugarsG': 2.6}, unit: 'ml')), isFalse);
    expect(QuickFilter.lowSugar.matches(_food({'sugarsG': 4}, unit: 'ml')), isFalse);
    expect(QuickFilter.lowSugar.matches(_food({'sugarsG': 4})), isTrue);
  });
}
