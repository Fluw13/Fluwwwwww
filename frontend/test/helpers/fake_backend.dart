import 'dart:async';
import 'dart:convert';

import 'package:frontend/data/api/api_config.dart';
import 'package:frontend/data/api/fluw_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'contract_fixtures.dart';

typedef FakeResponder = FutureOr<http.Response> Function(http.Request request);

/// In-memory Fluw backend for widget tests. Each route answers with the
/// responder set by the test; a route the test did not set fails loudly.
class FakeBackend {
  FakeBackend({FakeResponder? health, this.search, this.product, this.analysis})
    : health = health ?? ((_) => okHealth());

  FakeResponder health;
  FakeResponder? search;
  FakeResponder? product;
  FakeResponder? analysis;

  final List<Uri> requests = [];

  late final FluwApiClient client = FluwApiClient(
    httpClient: MockClient(_handle),
    config: ApiConfig.parse('https://api.test'),
  );

  List<String> get paths => [for (final Uri url in requests) url.path];

  int countPath(bool Function(String path) test) => paths.where(test).length;

  static http.Response okHealth() =>
      http.Response('{"success":true,"status":"ok"}', 200);

  static http.Response fixture(String name) =>
      ContractFixture.load(name).toResponse();

  static http.Response json(
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

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request.url);
    final List<String> segments = request.url.pathSegments;
    final FakeResponder? responder = switch (segments) {
      ['health'] => health,
      ['api', 'v1', 'search'] => search,
      ['api', 'v1', 'products', _] => product,
      ['api', 'v1', 'products', _, 'analysis'] => analysis,
      _ => null,
    };
    if (responder == null) {
      throw StateError('FakeBackend chưa cấu hình ${request.url.path}');
    }
    return responder(request);
  }
}
