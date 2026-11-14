import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/data/food_item_json.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/source_status.dart';

import '../../../fixtures/food_api_samples.dart';

Map<String, Object?> _with(Map<String, Object?> base, Map<String, Object?> changes) => {...base, ...changes};

void main() {
  test(
    'món Open Food Facts: đúng nguồn, đơn vị, số liệu; chỉ số null thì không có trong Nutrients (không thành 0)',
    () {
      final item = foodItemFromJson(yoghurtSearchItem)!;

      expect(item.id, 'off:8934673607827');
      expect(item.source, FoodSource.openFoodFacts);
      expect(item.name, 'Vinamilk sữa chua dâu');
      expect(item.facts.unit, QuantityUnit.gram);
      expect(item.facts.per100[Nutrient.sugarsG], 14.7);
      expect(item.facts.per100[Nutrient.proteinG], 3);
      expect(item.facts.per100[Nutrient.saturatedFatG], isNull);
      expect(item.allergenTags, isNull);
      expect(item.attribution.license, 'ODbL');
    },
  );

  test('đồ uống theo 100 ml; danh sách dị ứng rỗng giữ là rỗng (khác với chưa biết); 0 vẫn là 0', () {
    final item = foodItemFromJson(colaItem)!;

    expect(item.facts.unit, QuantityUnit.milliliter);
    expect(item.allergenTags, isEmpty);
    expect(item.facts.per100[Nutrient.fatG], 0);
    expect(item.attribution.imageLicense, 'CC BY-SA');
    expect(item.imageUrl.toString(), startsWith('https://images.openfoodfacts.org/'));
  });

  test('món USDA đọc được', () {
    final item = foodItemFromJson(chickenItem)!;

    expect(item.source, FoodSource.usda);
    expect(item.facts.per100[Nutrient.proteinG], 31.02);
  });

  test('món sai hợp đồng thì bỏ, không làm hỏng cả danh sách', () {
    final broken = [
      _with(yoghurtSearchItem, {'source': 'mystery'}),
      _with(yoghurtSearchItem, {
        'basis': {'amount': 1, 'unit': 'g'},
      }),
      _with(yoghurtSearchItem, {
        'basis': {'amount': 100, 'unit': 'cup'},
      }),
      _with(yoghurtSearchItem, {
        'nutrients': {'proteinG': -1},
      }),
      _with(yoghurtSearchItem, {'attribution': null}),
      _with(yoghurtSearchItem, {'id': 5}),
      'không phải object',
    ];
    for (final json in broken) {
      expect(foodItemFromJson(json), isNull, reason: '$json');
    }
  });

  test('chỉ nhận link https; tên rỗng thành null', () {
    final item = foodItemFromJson(_with(colaItem, {'imageUrl': 'http://example.com/a.jpg', 'name': '  '}))!;

    expect(item.imageUrl, isNull);
    expect(item.name, isNull);
  });

  test('kết quả tìm kiếm: bỏ món hỏng, đọc trạng thái nguồn, nhận ra khi thiếu kết quả', () {
    final response = searchResponseFromJson(
      searchBody('sữa', [
        yoghurtSearchItem,
        {'id': 'bad'},
        chickenItem,
      ], usda: 'unavailable'),
    );

    expect(response.items.map((item) => item.id), ['off:8934673607827', 'usda:171477']);
    expect(response.sources, {FoodSource.openFoodFacts: SourceStatus.ok, FoodSource.usda: SourceStatus.unavailable});
    expect(response.isPartial, isTrue);
    expect(searchResponseFromJson(searchBody('x', [], usda: 'not_configured')).isPartial, isFalse);
  });
}
