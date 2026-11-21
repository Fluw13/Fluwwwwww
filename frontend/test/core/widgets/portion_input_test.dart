import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/widgets/portion_input.dart';

void main() {
  test('nhận dấu phẩy và dấu chấm thập phân, bỏ dấu cách, giới hạn 1 đến 2000', () {
    expect(parsePortion('1,5', QuantityUnit.gram).$1, 1.5);
    expect(parsePortion(' 150 ', QuantityUnit.gram).$1, 150);
    expect(parsePortion('1', QuantityUnit.gram).$1, 1);
    expect(parsePortion('2000', QuantityUnit.gram).$1, 2000);
    for (final text in ['0,5', '2000.01', '1.000', '', 'abc']) {
      expect(parsePortion(text, QuantityUnit.gram).$1, isNull, reason: text);
    }
  });

  test('lời báo ghi khoảng "1–2000" theo đơn vị, không viết "2,000" dễ đọc thành 2', () {
    expect(parsePortion('0', QuantityUnit.gram).$2, 'Khẩu phần phải trong khoảng 1–2000 g.');
    expect(parsePortion('0', QuantityUnit.milliliter).$2, 'Khẩu phần phải trong khoảng 1–2000 ml.');
    expect(parsePortion('150', QuantityUnit.gram).$2, isNull);
  });
}
