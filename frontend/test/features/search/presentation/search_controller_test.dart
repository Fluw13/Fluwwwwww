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
}
