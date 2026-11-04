import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/trusted_image_url.dart';

void main() {
  test('nhận ảnh https của Open Food Facts', () {
    expect(
      isTrustedImageUrl(
        'https://images.openfoodfacts.org/images/products/893/front_vi.400.jpg',
      ),
      isTrue,
    );
    expect(
      isTrustedImageUrl('https://static.openfoodfacts.org/images/logo.png'),
      isTrue,
    );
  });

  test('từ chối http, host lạ, host giả mạo và chuỗi rỗng', () {
    expect(isTrustedImageUrl('http://images.openfoodfacts.org/a.jpg'), isFalse);
    expect(isTrustedImageUrl('https://example.com/a.jpg'), isFalse);
    expect(
      isTrustedImageUrl('https://openfoodfacts.org.evil.com/a.jpg'),
      isFalse,
    );
    expect(isTrustedImageUrl('https://evilopenfoodfacts.org/a.jpg'), isFalse);
    expect(isTrustedImageUrl(''), isFalse);
    expect(isTrustedImageUrl('không phải url'), isFalse);
  });

  test('chỉ nhận 2 máy chủ ảnh trong contract, không nhận tên miền con khác hay cổng lạ', () {
    expect(
      isTrustedImageUrl('https://world.openfoodfacts.org/images/a.jpg'),
      isFalse,
    );
    expect(isTrustedImageUrl('https://openfoodfacts.org/a.jpg'), isFalse);
    expect(isTrustedImageUrl('https://IMAGES.openfoodfacts.org/a.jpg'), isTrue);
    expect(
      isTrustedImageUrl('https://images.openfoodfacts.org:8443/a.jpg'),
      isFalse,
    );
    expect(
      isTrustedImageUrl('https://user@images.openfoodfacts.org/a.jpg'),
      isFalse,
    );
  });

  test('trustedImageUrlOrNull bỏ URL không tin cậy', () {
    expect(trustedImageUrlOrNull(null), isNull);
    expect(trustedImageUrlOrNull('https://example.com/a.jpg'), isNull);
    expect(
      trustedImageUrlOrNull('https://static.openfoodfacts.org/a.jpg'),
      'https://static.openfoodfacts.org/a.jpg',
    );
  });
}
