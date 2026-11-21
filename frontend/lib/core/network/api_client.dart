import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluw/core/network/api_failure.dart';
import 'package:http/http.dart' as http;

/// Talks JSON with the Fluw backend and turns every failure into an [ApiFailure].
final class ApiClient {
  ApiClient({required this.httpClient, required this.baseUri, required this.timeout});

  final http.Client httpClient;
  final Uri baseUri;
  final Duration timeout;

  Future<Map<String, Object?>> getJson(String path, {Map<String, String>? query}) => _send(
    () => httpClient.get(
      baseUri.replace(path: path, queryParameters: query),
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Sends raw bytes (a photo) and reads the JSON answer.
  Future<Map<String, Object?>> postBytes(String path, List<int> bytes, {required String contentType}) => _send(
    () => httpClient.post(
      baseUri.replace(path: path),
      headers: {'Accept': 'application/json', 'Content-Type': contentType},
      body: bytes,
    ),
  );

  Future<Map<String, Object?>> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const TimeoutFailure();
    } on IOException {
      // Covers sockets and TLS (HandshakeException): captive Wi-Fi portals, intercepting proxies, a wrong clock.
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    }

    // A 5xx that is not the backend's own error body comes from the host in front of it, not from Fluw.
    final unreadable = response.statusCode >= 500 ? const ServerUnavailableFailure() : const InvalidResponseFailure();
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw unreadable;
    }
    if (body is! Map<String, Object?>) {
      throw unreadable;
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
    throw unreadable;
  }
}
