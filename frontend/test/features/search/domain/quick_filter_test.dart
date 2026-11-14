import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/search/data/food_item_json.dart';
import 'package:fluw/features/search/domain/quick_filter.dart';

import '../../../fixtures/food_api_samples.dart';

void main() {
  final yoghurt = foodItemFromJson(yoghurtSearchItem)!;
  final cola = foodItemFromJson(colaItem)!;
  final chicken = foodItemFromJson(chickenItem)!;
  final noData = foodItemFromJson({...colaItem, 'nutrients': <String, Object?>{}})!;

  test('ít đường dưới 5 g, giàu protein trên 20 g, dưới 200 kcal (theo 100 g/ml)', () {
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

  test('đúng ngưỡng thì không đạt (dưới 5 g nghĩa là nhỏ hơn 5)', () {
    final exactly5 = foodItemFromJson({
      ...colaItem,
      'nutrients': {'sugarsG': 5, 'proteinG': 20, 'energyKcal': 200},
    })!;

    for (final filter in QuickFilter.values) {
      expect(filter.matches(exactly5), isFalse, reason: '$filter');
    }
  });
}
