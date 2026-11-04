import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/api/api_cancel_token.dart';
import 'package:frontend/data/api/api_config.dart';
import 'package:frontend/data/api/api_error_kind.dart';
import 'package:frontend/data/api/api_timeouts.dart';
import 'package:frontend/data/api/fluw_api_client.dart';
import 'package:frontend/data/api/fluw_api_exception.dart';
import 'package:frontend/models/analysis/product_analysis.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/contract_fixtures.dart';

final ApiConfig _config = ApiConfig.parse('https://api.test');

http.Response _json(
  Object body,
  int status, {
  Map<String, String> headers = const {},
}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8', ...headers},
  );
}

http.Response _error(
  int status,
  String code, {
  String? message,
  Map<String, String> headers = const {},
}) {
  return _json(
    {'success': false, 'error': message ?? 'Lỗi $code', 'code': code},
    status,
    headers: headers,
  );
}

FluwApiClient _client(
  MockClientHandler handler, {
  ApiTimeouts timeouts = const ApiTimeouts(),
  DateTime? now,
}) {
  return FluwApiClient(
    httpClient: MockClient(handler),
    config: _config,
    timeouts: timeouts,
    now: now == null ? null : () => now,
  );
}

Matcher _throwsKind(ApiErrorKind kind) =>
    throwsA(isA<FluwApiException>().having((e) => e.kind, 'kind', kind));

void main() {
  group('đường dẫn request', () {
    test(
      'tìm kiếm mã hóa từ khóa trong query, bỏ khoảng trắng đầu cuối',
      () async {
        Uri? url;
        final FluwApiClient client = _client((request) async {
          url = request.url;
          return ContractFixture.load('search-results').toResponse();
        });

        await client.search('  mì hảo hảo & bánh/1  ');

        expect(url?.origin, 'https://api.test');
        expect(url?.path, '/api/v1/search');
        expect(url?.queryParameters, {'q': 'mì hảo hảo & bánh/1'});
      },
    );

    test(
      'mã vạch là một đoạn đường dẫn, ký tự lạ không đổi được route',
      () async {
        final List<Uri> urls = [];
        final FluwApiClient client = _client((request) async {
          urls.add(request.url);
          return _error(400, 'INVALID_BARCODE');
        });

        await expectLater(
          client.product('../health'),
          _throwsKind(ApiErrorKind.invalidBarcode),
        );
        await expectLater(
          client.analysis('12/34'),
          _throwsKind(ApiErrorKind.invalidBarcode),
        );

        expect(urls[0].pathSegments, ['api', 'v1', 'products', '../health']);
        expect(urls[1].pathSegments, [
          'api',
          'v1',
          'products',
          '12/34',
          'analysis',
        ]);
      },
    );

    test(
      'gửi Accept: application/json và dùng AbortableRequest có abortTrigger',
      () async {
        http.BaseRequest? sent;
        final FluwApiClient client = FluwApiClient(
          httpClient: MockClient.streaming((request, _) async {
            sent = request;
            return http.StreamedResponse(
              Stream.value(utf8.encode('{"success":true,"status":"ok"}')),
              200,
            );
          }),
          config: _config,
        );

        await client.wakeUp();

        expect(
          sent,
          isA<http.Abortable>().having(
            (r) => r.abortTrigger,
            'abortTrigger',
            isNotNull,
          ),
        );
        expect(sent?.headers['accept'], 'application/json');
        expect(sent?.url.toString(), 'https://api.test/health');
      },
    );
  });

  group('phản hồi thành công', () {
    test('đọc sản phẩm và giải thích từ fixture', () async {
      final FluwApiClient client = _client((request) async {
        return request.url.path.endsWith('/analysis')
            ? ContractFixture.load('analysis-ok').toResponse()
            : ContractFixture.load('product-food-complete').toResponse();
      });

      expect((await client.product('8930000000019')).score.total.value, 31);
      expect(
        (await client.analysis('8930000000019')).explanation?.summary,
        isNotEmpty,
      );
    });

    test('AI lỗi vẫn là HTTP 200: trả aiError, không ném lỗi', () async {
      final FluwApiClient client = _client(
        (_) async =>
            ContractFixture.load('analysis-ai-daily-limit').toResponse(),
      );

      expect(
        (await client.analysis('8930000000033')).aiError,
        AiErrorCode.dailyLimit,
      );
    });
  });

  group('lỗi từ máy chủ', () {
    test(
      '400 INVALID_QUERY giữ mã, HTTP status và thông điệp tiếng Việt',
      () async {
        final ContractFixture fixture = ContractFixture.load(
          'error-invalid-query',
        );
        final FluwApiClient client = _client((_) async => fixture.toResponse());

        await expectLater(
          client.search('a'),
          throwsA(
            isA<FluwApiException>()
                .having((e) => e.kind, 'kind', ApiErrorKind.invalidQuery)
                .having((e) => e.code, 'code', 'INVALID_QUERY')
                .having((e) => e.statusCode, 'statusCode', 400)
                .having(
                  (e) => e.message,
                  'message',
                  'Từ khóa tìm kiếm cần từ 2 đến 100 ký tự.',
                )
                .having((e) => e.canRetry, 'canRetry', isFalse),
          ),
        );
      },
    );

    test('404 PRODUCT_NOT_FOUND không cho thử lại', () async {
      final FluwApiClient client = _client(
        (_) async =>
            ContractFixture.load('error-product-not-found').toResponse(),
      );

      await expectLater(
        client.product('8930000000101'),
        throwsA(
          isA<FluwApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.productNotFound)
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.canRetry, 'canRetry', isFalse),
        ),
      );
    });

    test('429 đọc Retry-After dạng số giây', () async {
      final FluwApiClient client = _client(
        (_) async => ContractFixture.load('error-rate-limited').toResponse(),
      );

      await expectLater(
        client.search('Vĩnh Hảo'),
        throwsA(
          isA<FluwApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.rateLimited)
              .having((e) => e.statusCode, 'statusCode', 429)
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(seconds: 60),
              )
              .having((e) => e.canRetry, 'canRetry', isTrue),
        ),
      );
    });

    test('429 đọc Retry-After dạng ngày giờ HTTP', () async {
      final FluwApiClient client = _client(
        (_) async => _error(
          429,
          'RATE_LIMITED',
          headers: {'retry-after': 'Wed, 04 Nov 2026 10:00:45 GMT'},
        ),
        now: DateTime.utc(2026, 11, 4, 10, 0, 0),
      );

      await expectLater(
        client.search('sữa'),
        throwsA(
          isA<FluwApiException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 45),
          ),
        ),
      );
    });

    test('Retry-After hỏng hoặc đã qua thì không khóa nút quá mức', () async {
      final FluwApiClient broken = _client(
        (_) async =>
            _error(429, 'RATE_LIMITED', headers: {'retry-after': 'sớm'}),
      );
      await expectLater(
        broken.search('sữa'),
        throwsA(
          isA<FluwApiException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            isNull,
          ),
        ),
      );

      final FluwApiClient past = _client(
        (_) async => _error(
          429,
          'RATE_LIMITED',
          headers: {'retry-after': 'Wed, 04 Nov 2026 09:00:00 GMT'},
        ),
        now: DateTime.utc(2026, 11, 4, 10),
      );
      await expectLater(
        past.search('sữa'),
        throwsA(
          isA<FluwApiException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            Duration.zero,
          ),
        ),
      );
    });

    test('503 UPSTREAM_RATE_LIMITED kèm Retry-After', () async {
      final FluwApiClient client = _client(
        (_) async =>
            ContractFixture.load('error-upstream-rate-limited').toResponse(),
      );

      await expectLater(
        client.product('8930000000118'),
        throwsA(
          isA<FluwApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.upstreamRateLimited)
              .having((e) => e.statusCode, 'statusCode', 503)
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(seconds: 12),
              ),
        ),
      );
    });

    for (final (int status, String code, ApiErrorKind kind) in [
      (502, 'UPSTREAM_UNAVAILABLE', ApiErrorKind.upstreamUnavailable),
      (504, 'UPSTREAM_TIMEOUT', ApiErrorKind.upstreamTimeout),
      (500, 'INTERNAL_ERROR', ApiErrorKind.internalError),
      (404, 'ROUTE_NOT_FOUND', ApiErrorKind.routeNotFound),
      (400, 'BAD_REQUEST', ApiErrorKind.badRequest),
    ]) {
      test('$status $code', () async {
        final FluwApiClient client = _client((_) async => _error(status, code));
        await expectLater(
          client.product('8930000000019'),
          throwsA(
            isA<FluwApiException>()
                .having((e) => e.kind, 'kind', kind)
                .having((e) => e.statusCode, 'statusCode', status)
                .having((e) => e.message, 'message', 'Lỗi $code'),
          ),
        );
      });
    }

    test('mã lạ thì phân loại theo HTTP status, vẫn giữ mã gốc', () async {
      final FluwApiClient client = _client(
        (_) async => _error(503, 'NEW_CODE'),
      );
      await expectLater(
        client.product('8930000000019'),
        throwsA(
          isA<FluwApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.serverUnavailable)
              .having((e) => e.code, 'code', 'NEW_CODE'),
        ),
      );
    });

    test(
      'thông điệp rỗng hoặc dài hơn 200 ký tự thì dùng thông điệp mặc định',
      () async {
        final FluwApiClient empty = _client(
          (_) async => _error(504, 'UPSTREAM_TIMEOUT', message: '   '),
        );
        await expectLater(
          empty.product('8930000000019'),
          throwsA(
            isA<FluwApiException>().having(
              (e) => e.message,
              'message',
              ApiErrorKind.upstreamTimeout.defaultMessage,
            ),
          ),
        );

        final FluwApiClient long = _client(
          (_) async => _error(500, 'INTERNAL_ERROR', message: 'x' * 201),
        );
        await expectLater(
          long.product('8930000000019'),
          throwsA(
            isA<FluwApiException>().having(
              (e) => e.message,
              'message',
              ApiErrorKind.internalError.defaultMessage,
            ),
          ),
        );

        final FluwApiClient exact = _client(
          (_) async => _error(500, 'INTERNAL_ERROR', message: 'y' * 200),
        );
        await expectLater(
          exact.product('8930000000019'),
          throwsA(
            isA<FluwApiException>().having(
              (e) => e.message,
              'message',
              'y' * 200,
            ),
          ),
        );
      },
    );
  });

  group('phản hồi không dùng được', () {
    test('trang HTML 520 của Cloudflare là "máy chủ tạm lỗi"', () async {
      final FluwApiClient client = _client(
        (_) async => http.Response(
          '<!DOCTYPE html><html><body>Error 520</body></html>',
          520,
          headers: {'content-type': 'text/html'},
        ),
      );
      await expectLater(
        client.search('sữa'),
        throwsA(
          isA<FluwApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.serverUnavailable)
              .having((e) => e.statusCode, 'statusCode', 520)
              .having((e) => e.canRetry, 'canRetry', isTrue),
        ),
      );
    });

    test('body rỗng là "máy chủ tạm lỗi" dù HTTP 200 hay 502', () async {
      for (final int status in [200, 502]) {
        final FluwApiClient client = _client(
          (_) async => http.Response('', status),
        );
        await expectLater(
          client.product('8930000000019'),
          _throwsKind(ApiErrorKind.serverUnavailable),
        );
      }
    });

    test(
      'JSON đúng cú pháp nhưng sai cấu trúc là "dữ liệu không hợp lệ"',
      () async {
        for (final Object body in [
          <Object>[],
          {'success': true},
          {
            'success': true,
            'product': {'name': 'không có mã vạch'},
            'score': <String, dynamic>{},
          },
          {'status': 'ok'},
        ]) {
          final FluwApiClient client = _client((_) async => _json(body, 200));
          await expectLater(
            client.product('8930000000019'),
            _throwsKind(ApiErrorKind.invalidResponse),
          );
        }
      },
    );

    test('UTF-8 hỏng là phản hồi không phải JSON', () async {
      final FluwApiClient client = _client(
        (_) async => http.Response.bytes([0xff, 0xfe, 0x7b], 200),
      );
      await expectLater(
        client.search('sữa'),
        _throwsKind(ApiErrorKind.serverUnavailable),
      );
    });
  });

  group('mạng, timeout và hủy', () {
    test('lỗi kết nối là lỗi mạng', () async {
      final FluwApiClient client = _client(
        (_) async => throw http.ClientException('offline'),
      );
      await expectLater(
        client.search('sữa'),
        _throwsKind(ApiErrorKind.network),
      );
    });

    test('quá thời gian thì báo timeout', () async {
      final FluwApiClient client = _client(
        (_) => Completer<http.Response>().future,
        timeouts: const ApiTimeouts(coldSearch: Duration(milliseconds: 30)),
      );
      await expectLater(
        client.search('sữa'),
        _throwsKind(ApiErrorKind.timeout),
      );
    });

    test('trước khi /health trả OK dùng thời gian chờ dài, sau đó dùng thời gian chờ ngắn', () async {
      const ApiTimeouts timeouts = ApiTimeouts(
        coldProduct: Duration(milliseconds: 400),
        warmProduct: Duration(milliseconds: 40),
      );
      final FluwApiClient client = _client((request) async {
        if (request.url.path == '/health') {
          return _json({'success': true, 'status': 'ok'}, 200);
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return ContractFixture.load('product-food-complete').toResponse();
      }, timeouts: timeouts);

      expect(client.isServerAwake, isFalse);
      await client.product('8930000000019');

      final FluwApiClient fresh = _client((request) async {
        if (request.url.path == '/health') {
          return _json({'success': true, 'status': 'ok'}, 200);
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return ContractFixture.load('product-food-complete').toResponse();
      }, timeouts: timeouts);
      expect(await fresh.wakeUp(), isTrue);
      expect(fresh.isServerAwake, isTrue);
      await expectLater(
        fresh.product('8930000000019'),
        _throwsKind(ApiErrorKind.timeout),
      );
    });

    test(
      'bị timeout khi đã thức thì lần sau quay lại thời gian chờ dài',
      () async {
        int calls = 0;
        final FluwApiClient client = _client(
          (request) async {
            if (request.url.path == '/health') {
              return _json({'success': true, 'status': 'ok'}, 200);
            }
            calls++;
            if (calls == 1) return Completer<http.Response>().future;
            await Future<void>.delayed(const Duration(milliseconds: 80));
            return ContractFixture.load('search-empty').toResponse();
          },
          timeouts: const ApiTimeouts(
            coldSearch: Duration(seconds: 2),
            warmSearch: Duration(milliseconds: 30),
          ),
        );

        await client.wakeUp();
        await expectLater(
          client.search('sữa'),
          _throwsKind(ApiErrorKind.timeout),
        );
        expect(client.isServerAwake, isFalse);
        expect((await client.search('sữa')).isEmpty, isTrue);
        expect(client.isServerAwake, isTrue);
      },
    );

    test('hủy khi đang chờ thì kết thúc ngay với lỗi "đã hủy"', () async {
      final ApiCancelToken token = ApiCancelToken();
      final Completer<void> sent = Completer<void>();
      final FluwApiClient client = _client((_) {
        sent.complete();
        return Completer<http.Response>().future;
      });

      final Future<Object> pending = client.product(
        '8930000000019',
        cancelToken: token,
      );
      await sent.future;
      token.cancel();

      await expectLater(pending, _throwsKind(ApiErrorKind.cancelled));
    });

    test('client hỗ trợ abortTrigger nhận được tín hiệu hủy', () async {
      final ApiCancelToken token = ApiCancelToken();
      bool aborted = false;
      final FluwApiClient client = FluwApiClient(
        httpClient: MockClient.streaming((request, _) async {
          await (request as http.Abortable).abortTrigger;
          aborted = true;
          throw http.RequestAbortedException(request.url);
        }),
        config: _config,
      );

      final Future<Object> pending = client.search('sữa', cancelToken: token);
      await Future<void>.delayed(Duration.zero);
      token.cancel();

      await expectLater(pending, _throwsKind(ApiErrorKind.cancelled));
      await Future<void>.delayed(Duration.zero);
      expect(aborted, isTrue);
    });

    test('token đã hủy thì không gửi request', () async {
      int calls = 0;
      final FluwApiClient client = _client((_) async {
        calls++;
        return ContractFixture.load('search-empty').toResponse();
      });
      final ApiCancelToken token = ApiCancelToken()..cancel();

      await expectLater(
        client.search('sữa', cancelToken: token),
        _throwsKind(ApiErrorKind.cancelled),
      );
      expect(calls, 0);
    });
  });

  group('wakeUp', () {
    test('không ném lỗi khi mất mạng hoặc máy chủ lỗi', () async {
      expect(
        await _client((_) async => throw http.ClientException('offline'))
            .wakeUp(),
        isFalse,
      );
      expect(
        await _client((_) async => http.Response('<html></html>', 503))
            .wakeUp(),
        isFalse,
      );
    });
  });

  test(
    'toString không chứa thông điệp (có thể lặp lại mã vạch hay từ khóa)',
    () {
      final FluwApiException error = FluwApiException(
        kind: ApiErrorKind.productNotFound,
        message: 'Không tìm thấy sản phẩm có mã vạch 8930000000101',
        statusCode: 404,
        code: 'PRODUCT_NOT_FOUND',
      );
      expect(error.toString(), isNot(contains('8930000000101')));
    },
  );
}
