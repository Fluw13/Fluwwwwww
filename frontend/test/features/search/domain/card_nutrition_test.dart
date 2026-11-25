import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/search/data/food_item_json.dart';
import 'package:fluw/features/search/domain/card_nutrition.dart';

import '../../../fixtures/food_api_samples.dart';

void main() {
  final chicken = foodItemFromJson(chickenItem)!;
  final empty = foodItemFromJson({...colaItem, 'id': 'off:1', 'nutrients': <String, Object?>{}})!;
  final onlyFat = foodItemFromJson({
    ...colaItem,
    'id': 'off:2',
    'nutrients': {'fatG': 3, 'sodiumMg': 10},
  })!;
  final onlySugar = foodItemFromJson({
    ...colaItem,
    'id': 'off:3',
    'nutrients': {'sugarsG': 0},
  })!;

  test('có một trong ba số (kể cả 0) là có số liệu', () {
    expect(hasCardNutrition(onlySugar), isTrue);
    expect(hasCardNutrition(chicken), isTrue);
    expect(hasCardNutrition(empty), isFalse);
    expect(hasCardNutrition(onlyFat), isFalse, reason: 'thẻ chỉ hiện kcal, protein, đường');
  });

  test('chỉ món Open Food Facts có mã vạch mới được tra lại ở màn Chi tiết', () {
    expect(hasProductLookup(empty), isTrue);
    expect(hasProductLookup(chicken), isFalse, reason: 'USDA không có tra mã vạch');
    expect(hasProductLookup(foodItemFromJson({...colaItem, 'barcode': null})!), isFalse);
  });
}
