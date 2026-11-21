import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/search/data/food_item_json.dart';
import 'package:fluw/features/search/domain/result_ranking.dart';

import '../../../fixtures/food_api_samples.dart';

void main() {
  final yoghurt = foodItemFromJson(yoghurtSearchItem)!;
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

  test('món không có số nào trên thẻ (kcal, protein, đường) thì xếp cuối, còn lại giữ thứ tự nguồn', () {
    expect(withNutritionFirst([empty, yoghurt, onlyFat, chicken]), [yoghurt, chicken, empty, onlyFat]);
  });

  test('có một trong ba số (kể cả 0) là có số liệu', () {
    expect(hasCardNutrition(onlySugar), isTrue);
    expect(hasCardNutrition(chicken), isTrue);
    expect(hasCardNutrition(empty), isFalse);
    expect(hasCardNutrition(onlyFat), isFalse, reason: 'thẻ chỉ hiện kcal, protein, đường');
  });
}
