import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_config.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(MockClientHandler handler, {Duration timeout = const Duration(seconds: 5)}) =>
    ApiClient(httpClient: MockClient(handler), baseUri: Uri.parse('https://api.test'), timeout: timeout);

http.Response _json(Object body, int status) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

void main() {
  test('gọi đúng đường dẫn và tham số, đọc JSON có dấu tiếng Việt', () async {
    late Uri called;
    final client = _client((request) async {
      called = request.url;
      return _json({'query': 'sữa chua'}, 200);
    });

    final body = await client.getJson('/api/foods/search', query: {'q': 'sữa chua'});

    expect(body['query'], 'sữa chua');
    expect(called.toString(), 'https://api.test/api/foods/search?q=s%E1%BB%AFa+chua');
  });

  test('lỗi có body chuẩn thì giữ status, mã và lời nhắn của máy chủ', () async {
    final client = _client(
      (request) async => _json({
        'error': {'code': 'TOO_MANY_REQUESTS', 'message': 'Bạn tra cứu quá nhanh.'},
      }, 429),
    );

    await expectLater(
      client.getJson('/x'),
      throwsA(
        isA<ServerFailure>()
            .having((failure) => failure.statusCode, 'status', 429)
            .having((failure) => failure.code, 'code', 'TOO_MANY_REQUESTS')
            .having((failure) => failure.message, 'message', 'Bạn tra cứu quá nhanh.'),
      ),
    );
  });

  test('trang lỗi HTML, JSON không phải object, lỗi thiếu body chuẩn thì là phản hồi không đọc được', () async {
    for (final response in [
      http.Response('<html>502</html>', 502),
      _json([1, 2], 200),
      _json({'message': 'x'}, 500),
    ]) {
      await expectLater(_client((request) async => response).getJson('/x'), throwsA(isA<InvalidResponseFailure>()));
    }
  });

  test('mất mạng thì NetworkFailure, quá giờ thì TimeoutFailure', () async {
    await expectLater(
      _client((request) async => throw http.ClientException('offline')).getJson('/x'),
      throwsA(isA<NetworkFailure>()),
    );
    await expectLater(
      _client(
        (request) => Future.delayed(const Duration(seconds: 1), () => _json({}, 200)),
        timeout: const Duration(milliseconds: 10),
      ).getJson('/x'),
      throwsA(isA<TimeoutFailure>()),
    );
  });

  test('app chờ máy chủ thức dậy đủ lâu (gói free của Render chậm khoảng 50 giây)', () {
    expect(apiTimeout.inSeconds, greaterThanOrEqualTo(60));
    expect(apiBaseUrl, 'https://fluw.onrender.com');
  });
}
