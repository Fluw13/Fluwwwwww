import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/backend_warm_up.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(MockClient http) =>
    ApiClient(httpClient: http, baseUri: Uri.parse('https://api.test'), timeout: const Duration(seconds: 70));

void main() {
  test('gọi /health để đánh thức máy chủ', () async {
    final calls = <Uri>[];
    await wakeUpBackend(
      _client(
        MockClient((request) async {
          calls.add(request.url);
          return http.Response('{"status":"ok"}', 200);
        }),
      ),
    );

    expect(calls.single.path, '/health');
  });

  test('mất mạng hay máy chủ lỗi thì im lặng, không làm hỏng lúc mở app', () async {
    await expectLater(
      wakeUpBackend(_client(MockClient((request) async => throw http.ClientException('không có mạng')))),
      completes,
    );
    await expectLater(wakeUpBackend(_client(MockClient((request) async => http.Response('oops', 503)))), completes);
  });
}
