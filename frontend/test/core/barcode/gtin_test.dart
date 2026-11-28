import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/barcode/gtin.dart';

void main() {
  test('mã vạch hợp lệ: EAN-13, EAN-8, UPC-A, GTIN-14 (cùng mẫu với test backend)', () {
    for (final code in [
      '8934673607827',
      '3017624010701',
      '96385074',
      '049000004632',
      '0049000004632',
      '10012345678902',
    ]) {
      expect(isValidGtin(code), isTrue, reason: code);
    }
  });

  test('sai chữ số kiểm tra, sai độ dài, có chữ thì không hợp lệ', () {
    for (final code in ['8934673607828', '96385075', '123456789', '12345678901', '89346736O7827', '', ' 96385074']) {
      expect(isValidGtin(code), isFalse, reason: code);
    }
  });
}
