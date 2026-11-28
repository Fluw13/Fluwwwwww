import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/data/custom_product_mapper.dart';
import 'package:fluw/features/search/data/custom_product_repository.dart';
import 'package:fluw/features/search/domain/custom_product.dart';

import '../../../helpers/in_memory_database.dart';

CustomProduct _product(String id, {String name = 'Trà sữa latte', String? brand, String? barcode}) => CustomProduct(
  id: id,
  name: name,
  brand: brand,
  barcode: barcode,
  facts: NutritionFacts(
    per100: Nutrients({Nutrient.energyKcal: 25.9, Nutrient.sodiumMg: 0}),
    unit: QuantityUnit.milliliter,
  ),
  packageAmount: 440,
  servingAmount: 440,
  labelPerServing: true,
);

void main() {
  late AppDatabase database;
  late CustomProductRepository repository;
  var now = DateTime.utc(2026, 11, 28, 8);

  setUp(() {
    database = openInMemoryDatabase();
    repository = CustomProductRepository(database, clock: () => now);
  });
  tearDown(() => database.close());

  test('lưu rồi đọc lại theo id và mã vạch được đúng sản phẩm; số liệu thiếu vẫn là thiếu', () async {
    final product = _product('a', brand: 'Hãng X', barcode: '8935001282266');
    await repository.save(product);

    expect(await repository.findById('a'), product);
    expect(await repository.findByBarcode('8935001282266'), product);
    expect((await repository.findById('a'))!.facts.per100[Nutrient.proteinG], isNull);
    expect(await repository.findById('b'), isNull);
    expect(await repository.findByBarcode('96385074'), isNull);
  });

  test('mã UPC-A tìm được dù camera đọc thành EAN-13 có thêm số 0 đầu, và ngược lại', () async {
    await repository.save(_product('upc', barcode: '049000004632'));
    await repository.save(_product('ean', barcode: '0012345678905'));

    expect((await repository.findByBarcode('0049000004632'))?.id, 'upc');
    expect((await repository.findByBarcode('012345678905'))?.id, 'ean');
  });

  test('lưu lại cùng id thì thay; mã đã thuộc sản phẩm khác thì báo trùng và không ghi', () async {
    await repository.save(_product('a', barcode: '96385074'));
    await repository.save(_product('a', name: 'Tên mới', barcode: '96385074'));
    expect((await repository.findById('a'))!.name, 'Tên mới');

    await expectLater(
      repository.save(_product('b', name: 'Khác', barcode: '96385074')),
      throwsA(isA<DuplicateBarcodeException>().having((error) => error.existingName, 'existingName', 'Tên mới')),
    );
    await expectLater(
      repository.save(_product('c', barcode: '0096385074')),
      throwsA(isA<DuplicateBarcodeException>()),
      reason: 'cùng mã khi bỏ số 0 đầu',
    );
    expect(await repository.findById('b'), isNull);
    expect(await database.select(database.customProducts).get(), hasLength(1));
  });

  test('tìm theo tên hoặc hãng, có dấu hay không dấu, đủ mọi từ; mới sửa trước', () async {
    await repository.save(_product('a', name: 'Trà sữa latte'));
    now = now.add(const Duration(minutes: 1));
    await repository.save(_product('b', name: 'Sữa tươi', brand: 'Đà Lạt Milk'));
    now = now.add(const Duration(minutes: 1));
    await repository.save(_product('c', name: 'Trà xanh'));

    Future<List<String>> ids(String query) async => [for (final product in await repository.search(query)) product.id];

    expect(await ids('tra sua'), ['a']);
    expect(await ids('SỮA'), ['b', 'a']);
    expect(await ids('da lat'), ['b'], reason: 'hãng cũng được tìm, đ thành d');
    expect(await ids('trà'), ['c', 'a']);
    expect(await ids('cà phê'), isEmpty);
    expect(await ids('  '), isEmpty);
  });

  test('xóa thì không còn tìm thấy', () async {
    await repository.save(_product('a', barcode: '96385074'));
    await repository.delete('a');

    expect(await repository.findById('a'), isNull);
    expect(await repository.findByBarcode('96385074'), isNull);
    expect(await repository.search('trà'), isEmpty);
  });

  test('dòng không đọc được (đơn vị lạ, số âm) bị bỏ riêng, không làm hỏng các dòng khác', () async {
    await repository.save(_product('good', name: 'Trà đào'));
    final row = customProductToRow(_product('bad', name: 'Trà lạ'), updatedAt: now);
    await database.into(database.customProducts).insert(row.copyWith(unit: const Value('cup')));
    await database
        .into(database.customProducts)
        .insert(
          customProductToRow(_product('negative', name: 'Trà âm'), updatedAt: now).copyWith(proteinG: const Value(-1)),
        );

    expect([for (final product in await repository.search('trà')) product.id], ['good']);
    expect(await repository.findById('bad'), isNull);
  });
}
