import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiService.wakeUpServer', () {
    test('gọi đường dẫn /health của máy chủ', () async {
      Uri? requested;
      final ApiService service = ApiService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response('{"success":true,"status":"ok"}', 200);
        }),
      );

      await service.wakeUpServer();

      expect(requested?.path, '/health');
    });

    test('không ném lỗi khi không kết nối được máy chủ', () async {
      final ApiService service = ApiService(
        client: MockClient((request) async => throw http.ClientException('offline')),
      );

      await expectLater(service.wakeUpServer(), completes);
    });
  });

  group('ApiService.fetchProduct', () {
    test('trả thông báo lỗi của máy chủ khi mã vạch sai số kiểm tra', () async {
      final ApiService service = ApiService(
        client: MockClient((request) async => http.Response(
              '{"success":false,"error":"Mã vạch không hợp lệ (sai số kiểm tra). Vui lòng quét hoặc nhập lại."}',
              400,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );

      await expectLater(
        service.fetchProduct('8934563138164'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('số kiểm tra'))),
      );
    });
  });
}
