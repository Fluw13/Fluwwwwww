import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/custom_product.dart';
import 'package:fluw/features/search/domain/custom_product_draft.dart';

CustomProduct _valid(CustomProductDraft draft) => switch (draft.build(id: 'p1')) {
  ValidCustomProduct(:final product) => product,
  InvalidCustomProduct(:final fields, :final nutrients) => fail('không hợp lệ: $fields $nutrients'),
};

InvalidCustomProduct _invalid(CustomProductDraft draft) => switch (draft.build(id: 'p1')) {
  ValidCustomProduct() => fail('đáng lẽ không hợp lệ'),
  final InvalidCustomProduct invalid => invalid,
};

void main() {
  test('nhãn ghi theo 100 ml: giữ nguyên số, ô trống là không có số liệu, bỏ khoảng trắng', () {
    final product = _valid(
      const CustomProductDraft(
        name: '  Trà sữa latte ',
        brand: ' ',
        barcode: '8935001282266',
        unit: QuantityUnit.milliliter,
        packageAmount: '440',
        nutrients: {Nutrient.energyKcal: '26', Nutrient.proteinG: '0,8', Nutrient.sugarsG: ''},
      ),
    );

    expect(product.name, 'Trà sữa latte');
    expect(product.brand, isNull);
    expect(product.barcode, '8935001282266');
    expect(product.facts.unit, QuantityUnit.milliliter);
    expect(product.packageAmount, 440);
    expect(product.servingAmount, isNull);
    expect(product.labelPerServing, isFalse);
    expect(product.facts.per100[Nutrient.energyKcal], 26);
    expect(product.facts.per100[Nutrient.proteinG], 0.8);
    expect(product.facts.per100[Nutrient.sugarsG], isNull, reason: 'ô trống không phải 0');
  });

  test('nhãn ghi theo 1 khẩu phần 440 ml: đổi ra trong 100 ml, mở lại form thấy đúng số trên nhãn', () {
    const draft = CustomProductDraft(
      name: 'Trà sữa latte',
      unit: QuantityUnit.milliliter,
      labelPerServing: true,
      servingAmount: '440',
      nutrients: {Nutrient.energyKcal: '114', Nutrient.proteinG: '3.5', Nutrient.sodiumMg: '0'},
    );
    final product = _valid(draft);

    expect(product.facts.per100[Nutrient.energyKcal], closeTo(25.909, 0.001));
    expect(product.facts.per100[Nutrient.proteinG], closeTo(0.795, 0.001));
    expect(product.facts.per100[Nutrient.sodiumMg], 0, reason: '0 trên nhãn là số liệu thật');
    expect(product.servingAmount, 440);
    expect(product.labelPerServing, isTrue);

    final reopened = CustomProductDraft.fromProduct(product);
    expect(reopened.labelPerServing, isTrue);
    expect(reopened.nutrientText(Nutrient.energyKcal), '114');
    expect(reopened.nutrientText(Nutrient.proteinG), '3.5');
    expect(reopened.nutrientText(Nutrient.sodiumMg), '0');
    expect(reopened.nutrientText(Nutrient.fatG), '');
    expect(reopened, draft, reason: 'mở lại rồi lưu ngay không tính là đã sửa');
  });

  test('thiếu tên và năng lượng thì báo đúng ô; ghi theo khẩu phần mà thiếu khẩu phần cũng báo', () {
    final invalid = _invalid(const CustomProductDraft(labelPerServing: true));

    expect(invalid.fields, {
      CustomProductField.name: CustomProductIssue.required,
      CustomProductField.servingAmount: CustomProductIssue.required,
    });
    expect(invalid.nutrients, {Nutrient.energyKcal: CustomProductIssue.required});
  });

  test('số sai dạng, quá 2 chữ số thập phân hay âm thì báo; khẩu phần ngoài 1–2000 thì báo', () {
    final invalid = _invalid(
      const CustomProductDraft(
        name: 'A',
        servingAmount: '0',
        packageAmount: '2001',
        nutrients: {Nutrient.energyKcal: 'abc', Nutrient.proteinG: '1.234', Nutrient.fatG: '-1'},
      ),
    );

    expect(invalid.fields, {
      CustomProductField.servingAmount: CustomProductIssue.portionOutOfRange,
      CustomProductField.packageAmount: CustomProductIssue.portionOutOfRange,
    });
    expect(invalid.nutrients, {
      Nutrient.energyKcal: CustomProductIssue.invalidNumber,
      Nutrient.proteinG: CustomProductIssue.invalidNumber,
      Nutrient.fatG: CustomProductIssue.invalidNumber,
    });
  });

  test('mã vạch: sai độ dài và sai chữ số kiểm tra báo khác nhau; để trống được', () {
    CustomProductIssue? issue(String code) =>
        _invalidOrNull(CustomProductDraft(name: 'A', barcode: code, nutrients: const {Nutrient.energyKcal: '1'}));

    expect(issue('123456789'), CustomProductIssue.barcodeLength);
    expect(issue('8934673607828'), CustomProductIssue.barcodeCheckDigit);
    expect(issue('96385074'), isNull);
    expect(issue('  '), isNull);
  });

  test('quá mức có thể có trong 100 g (kể cả sau khi đổi từ khẩu phần) thì báo', () {
    final per100 = _invalid(
      const CustomProductDraft(
        name: 'A',
        nutrients: {Nutrient.energyKcal: '901', Nutrient.proteinG: '100.01', Nutrient.sodiumMg: '40001'},
      ),
    );
    expect(per100.nutrients, {
      Nutrient.energyKcal: CustomProductIssue.tooHighPer100,
      Nutrient.proteinG: CustomProductIssue.tooHighPer100,
      Nutrient.sodiumMg: CustomProductIssue.tooHighPer100,
    });

    final atLimit = _valid(
      const CustomProductDraft(
        name: 'A',
        nutrients: {Nutrient.energyKcal: '900', Nutrient.fatG: '100', Nutrient.sodiumMg: '40000'},
      ),
    );
    expect(atLimit.facts.per100[Nutrient.fatG], 100);

    final perServing = _invalid(
      const CustomProductDraft(
        name: 'A',
        labelPerServing: true,
        servingAmount: '20',
        nutrients: {Nutrient.energyKcal: '50', Nutrient.proteinG: '30'},
      ),
    );
    expect(perServing.nutrients, {Nutrient.proteinG: CustomProductIssue.tooHighPer100});
  });

  test('đường nhiều hơn carb, béo bão hòa nhiều hơn chất béo thì báo; thiếu số kia thì không so', () {
    final invalid = _invalid(
      const CustomProductDraft(
        name: 'A',
        nutrients: {
          Nutrient.energyKcal: '100',
          Nutrient.carbohydratesG: '10',
          Nutrient.sugarsG: '10.5',
          Nutrient.fatG: '2',
          Nutrient.saturatedFatG: '2.5',
        },
      ),
    );
    expect(invalid.nutrients, {
      Nutrient.sugarsG: CustomProductIssue.sugarsAboveCarbohydrates,
      Nutrient.saturatedFatG: CustomProductIssue.saturatedFatAboveFat,
    });

    final product = _valid(
      const CustomProductDraft(
        name: 'A',
        nutrients: {Nutrient.energyKcal: '100', Nutrient.sugarsG: '10', Nutrient.saturatedFatG: '3'},
      ),
    );
    expect(product.facts.per100[Nutrient.sugarsG], 10);
  });

  test('tên dài quá 100 ký tự thì báo', () {
    final invalid = _invalid(
      CustomProductDraft(name: 'a' * 101, brand: 'b' * 101, nutrients: const {Nutrient.energyKcal: '1'}),
    );
    expect(invalid.fields, {
      CustomProductField.name: CustomProductIssue.tooLong,
      CustomProductField.brand: CustomProductIssue.tooLong,
    });
  });

  test('so sánh bản nháp: ô dinh dưỡng trống bằng không có; khoảng trắng không tính; đổi số thì khác', () {
    const base = CustomProductDraft(name: 'A', nutrients: {Nutrient.energyKcal: '10'});

    expect(const CustomProductDraft(name: 'A ', nutrients: {Nutrient.energyKcal: '10', Nutrient.fatG: ' '}), base);
    expect(
      const CustomProductDraft(name: 'A ', nutrients: {Nutrient.energyKcal: '10', Nutrient.fatG: ' '}).hashCode,
      base.hashCode,
    );
    expect(const CustomProductDraft(name: 'A', nutrients: {Nutrient.energyKcal: '11'}), isNot(base));
    expect(
      const CustomProductDraft(name: 'A', unit: QuantityUnit.milliliter, nutrients: {Nutrient.energyKcal: '10'}),
      isNot(base),
    );
  });
}

CustomProductIssue? _invalidOrNull(CustomProductDraft draft) => switch (draft.build(id: 'p1')) {
  ValidCustomProduct() => null,
  InvalidCustomProduct(:final fields) => fields[CustomProductField.barcode],
};
