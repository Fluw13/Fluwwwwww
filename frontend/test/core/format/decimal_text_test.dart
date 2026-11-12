import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/format/decimal_text.dart';

void main() {
  test('đọc số thập phân có dấu phẩy hoặc dấu chấm', () {
    expect(parseDecimal('58,5'), 58.5);
    expect(parseDecimal('58.5'), 58.5);
    expect(parseDecimal(' 165 '), 165);
    expect(parseDecimal('58,25'), 58.25);
    expect(parseDecimal('58.125', maxFractionDigits: 3), 58.125);
  });

  test('chuỗi không phải số dương hữu hạn thì trả null', () {
    for (final text in ['', '-5', 'abc', '1,2,3', '58.', '.5', '1e3', 'NaN', 'Infinity', '5 kg', '58.125']) {
      expect(parseDecimal(text), isNull, reason: text);
    }
  });

  test('in số thập phân bỏ số 0 thừa', () {
    expect(formatDecimal(58.5), '58.5');
    expect(formatDecimal(165), '165');
    expect(formatDecimal(53.04), '53');
    expect(formatDecimal(0.25, maxFractionDigits: 2), '0.25');
    expect(formatDecimal(2.45), '2.5');
  });

  test('in số nguyên có dấu phẩy ngăn hàng nghìn', () {
    expect(formatWhole(1850.4), '1,850');
    expect(formatWhole(999.5), '1,000');
    expect(formatWhole(2000), '2,000');
    expect(formatWhole(1234567), '1,234,567');
    expect(formatWhole(42), '42');
    expect(formatWhole(-1500), '-1,500');
  });
}
