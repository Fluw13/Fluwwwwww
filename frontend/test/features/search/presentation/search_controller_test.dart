import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_client_provider.dart';
import 'package:fluw/features/search/presentation/search_controller.dart';
import 'package:fluw/features/search/presentation/search_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';

void main() {
  test('tìm hai lần liền: câu trả lời cũ về sau không đè kết quả mới', () async {
    final slow = Completer<http.Response>();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(
            httpClient: MockClient((request) {
              final query = request.url.queryParameters['q']!;
              if (query == 'cũ') {
                return slow.future;
              }
              return Future.value(http.Response.bytes(utf8.encode(jsonEncode(searchBody(query, [chickenItem]))), 200));
            }),
            baseUri: Uri.parse('https://api.test'),
            timeout: const Duration(seconds: 5),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(searchControllerProvider.notifier);

    final oldSearch = controller.search('cũ');
    await controller.search('mới');
    slow.complete(http.Response.bytes(utf8.encode(jsonEncode(searchBody('cũ', [yoghurtSearchItem]))), 200));
    await oldSearch;

    expect((container.read(searchControllerProvider) as SearchLoaded).response.query, 'mới');
  });

  test('từ khóa ngắn hơn 2 hoặc dài hơn 100 ký tự thì không gọi máy chủ', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(
            httpClient: MockClient((request) async {
              calls++;
              return http.Response('{}', 200);
            }),
            baseUri: Uri.parse('https://api.test'),
            timeout: const Duration(seconds: 5),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(searchControllerProvider.notifier).search(' a ');
    await container.read(searchControllerProvider.notifier).search('x' * 101);

    expect(calls, 0);
    expect(container.read(searchControllerProvider), isA<SearchIdle>());
  });

  test('từ tiếng Anh (món nhận diện từ ảnh) gửi kèm cho USDA, giữ cho nút Thử lại; từ sai thì bỏ', () async {
    final asked = <Map<String, String>>[];
    var fail = true;
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(
            httpClient: MockClient((request) async {
              asked.add(request.url.queryParameters);
              if (fail) {
                throw http.ClientException('mất mạng');
              }
              return http.Response.bytes(utf8.encode(jsonEncode(searchBody('cà chua', [chickenItem]))), 200);
            }),
            baseUri: Uri.parse('https://api.test'),
            timeout: const Duration(seconds: 5),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(searchControllerProvider.notifier);

    await controller.search('cà chua', englishQuery: '  tomato ');
    final failed = container.read(searchControllerProvider) as SearchFailed;
    expect(asked.single, {'q': 'cà chua', 'en': 'tomato'});
    expect(failed.englishQuery, 'tomato');

    fail = false;
    await controller.search(failed.query, englishQuery: failed.englishQuery);
    expect(asked.last, {'q': 'cà chua', 'en': 'tomato'});

    await controller.search('bánh xèo', englishQuery: 't');
    expect(asked.last, {'q': 'bánh xèo'});
  });

  test(
    'gõ tên đồ tươi có trong bảng thì gửi kèm tiếng Anh cho USDA và giữ để hiện; từ ảnh thì ưu tiên từ ảnh',
    () async {
      final asked = <Map<String, String>>[];
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            ApiClient(
              httpClient: MockClient((request) async {
                asked.add(request.url.queryParameters);
                final body = searchBody(request.url.queryParameters['q']!, [chickenItem]);
                return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
              }),
              baseUri: Uri.parse('https://api.test'),
              timeout: const Duration(seconds: 5),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(searchControllerProvider.notifier);

      await controller.search('Ức gà luộc');
      expect(asked.last, {'q': 'Ức gà luộc', 'en': 'chicken breast'});
      expect((container.read(searchControllerProvider) as SearchLoaded).englishQuery, 'chicken breast');

      await controller.search('cà chua', englishQuery: 't');
      expect(asked.last, {'q': 'cà chua', 'en': 'tomato'}, reason: 'từ ảnh không hợp lệ thì dùng bảng');

      await controller.search('cà chua', englishQuery: 'cherry tomato');
      expect(asked.last, {'q': 'cà chua', 'en': 'cherry tomato'});

      await controller.search('sữa chua vinamilk');
      expect(asked.last, {'q': 'sữa chua vinamilk'});
      expect((container.read(searchControllerProvider) as SearchLoaded).englishQuery, isNull);
    },
  );
}
