import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/search/data/food_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';

FoodApi _api(MockClientHandler handler) => FoodApi(
  ApiClient(
    httpClient: MockClient(handler),
    baseUri: Uri.parse('https://api.test'),
    timeout: const Duration(seconds: 5),
  ),
);

http.Response _json(Object body, int status) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  test('tra mã vạch trả món đầy đủ (có dị ứng)', () async {
    late Uri called;
    final api = _api((request) async {
      called = request.url;
      return _json({'item': yoghurtProduct}, 200);
    });

    final item = await api.lookUpBarcode('8934673607827');

    expect(called.path, '/api/foods/barcode/8934673607827');
    expect(item!.allergenTags, ['en:milk']);
  });

  test('mã không có sản phẩm thì null; lỗi khác vẫn báo lỗi', () async {
    final notFound = _api(
      (request) async => _json({
        'error': {'code': 'PRODUCT_NOT_FOUND', 'message': 'Không có.'},
      }, 404),
    );
    final down = _api(
      (request) async => _json({
        'error': {'code': 'SOURCES_UNAVAILABLE', 'message': 'Lỗi nguồn.'},
      }, 503),
    );

    expect(await notFound.lookUpBarcode('96385074'), isNull);
    await expectLater(down.lookUpBarcode('96385074'), throwsA(isA<ServerFailure>()));
  });

  test('máy chủ trả món sai hợp đồng thì báo phản hồi không đọc được', () async {
    final api = _api(
      (request) async => _json({
        'item': {'id': 'x'},
      }, 200),
    );

    await expectLater(api.lookUpBarcode('96385074'), throwsA(isA<InvalidResponseFailure>()));
  });

  test(
    'mã vạch bị máy chủ coi là sai dạng (mã lỗi trong Open Food Facts) cũng là không có, không cho thử lại vô ích',
    () async {
      final api = _api(
        (request) async => _json({
          'error': {'code': 'INVALID_BARCODE', 'message': 'Mã vạch không hợp lệ.'},
        }, 400),
      );

      expect(await api.lookUpBarcode('12345'), isNull);
    },
  );
}
