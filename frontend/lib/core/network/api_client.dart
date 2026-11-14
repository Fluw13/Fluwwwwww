import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluw/core/network/api_failure.dart';
import 'package:http/http.dart' as http;

/// GETs JSON from the Fluw backend and turns every failure into an [ApiFailure].
final class ApiClient {
  ApiClient({required this.httpClient, required this.baseUri, required this.timeout});

  final http.Client httpClient;
  final Uri baseUri;
  final Duration timeout;

  Future<Map<String, Object?>> getJson(String path, {Map<String, String>? query}) async {
    final uri = baseUri.replace(path: path, queryParameters: query);
    final http.Response response;
    try {
      response = await httpClient.get(uri, headers: {'Accept': 'application/json'}).timeout(timeout);
    } on TimeoutException {
      throw const TimeoutFailure();
    } on IOException {
      // Covers sockets and TLS (HandshakeException): captive Wi-Fi portals, intercepting proxies, a wrong clock.
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    }

    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const InvalidResponseFailure();
    }
    if (body is! Map<String, Object?>) {
      throw const InvalidResponseFailure();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final error = body['error'];
    if (error is Map<String, Object?> && error['code'] is String && error['message'] is String) {
      throw ServerFailure(
        statusCode: response.statusCode,
        code: error['code']! as String,
        message: error['message']! as String,
      );
    }
    throw const InvalidResponseFailure();
  }
}
