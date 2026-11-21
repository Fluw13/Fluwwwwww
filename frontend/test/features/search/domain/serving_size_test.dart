import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/serving_size.dart';

void main() {
  test('đọc số gram/ml của khẩu phần trên bao bì, lấy số cuối cùng', () {
    expect(servingAmount('1 bottle (355 ml)', QuantityUnit.milliliter), 355);
    expect(servingAmount('1 portion (100 g)', QuantityUnit.gram), 100);
    expect(servingAmount('30g', QuantityUnit.gram), 30);
    expect(servingAmount('2 bánh (25,5 g)', QuantityUnit.gram), 25.5);
    expect(servingAmount('1 cup (8 fl oz) 240 mL', QuantityUnit.milliliter), 240);
    expect(servingAmount('1 hộp 180 gam', QuantityUnit.gram), 180);
    expect(servingAmount('50 grams', QuantityUnit.gram), 50);
    expect(servingAmount('100 g (1 hũ 120 g)', QuantityUnit.gram), 120);
  });

  test('làm tròn đến 0,1 như ô khẩu phần', () {
    expect(servingAmount('1 pot (33.33 g)', QuantityUnit.gram), 33.3);
  });

  test('khác đơn vị của số liệu thì không đổi g sang ml', () {
    expect(servingAmount('1 can (330 ml)', QuantityUnit.gram), isNull);
    expect(servingAmount('1 portion (100 g)', QuantityUnit.milliliter), isNull);
  });

  test('không có số đo hợp lệ thì null', () {
    for (final text in [null, '', '1 portion', '50 gói', '1 kg', '15 mg', '0 g', '2500 g', '1/2 cup']) {
      expect(servingAmount(text, QuantityUnit.gram), isNull, reason: '$text');
    }
  });
}
