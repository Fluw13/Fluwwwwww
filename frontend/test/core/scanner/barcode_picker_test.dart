import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/scanner/barcode_picker.dart';

void main() {
  test('chọn mã vạch sản phẩm đầu tiên hợp lệ (GTIN 8, 12, 13, 14 chữ số)', () {
    expect(firstProductBarcode(['8934563138165']), '8934563138165');
    expect(firstProductBarcode(['12345678']), '12345678');
    expect(firstProductBarcode(['012345678905']), '012345678905');
    expect(firstProductBarcode(['10012345678902']), '10012345678902');
    expect(firstProductBarcode([null, 'https://fluw.app', ' 8934563138165 ']), '8934563138165');
  });

  test('bỏ qua mọi giá trị không phải mã vạch sản phẩm', () {
    expect(firstProductBarcode([]), isNull);
    expect(firstProductBarcode([null, '']), isNull);
    expect(firstProductBarcode(['1234567']), isNull);
    expect(firstProductBarcode(['123456789']), isNull);
    expect(firstProductBarcode(['12345678901']), isNull);
    expect(firstProductBarcode(['123456789012345']), isNull);
    expect(firstProductBarcode(['89345631381ab']), isNull);
    expect(firstProductBarcode(['https://example.com/8934563138165']), isNull);
  });
}
