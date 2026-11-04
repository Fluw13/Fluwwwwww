import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/analysis/product_analysis.dart';
import '../../models/product/product_details.dart';
import '../../models/search/search_results.dart';
import '../json/json_fields.dart';
import 'api_cancel_token.dart';
import 'api_config.dart';
import 'api_error_kind.dart';
import 'api_timeouts.dart';
import 'fluw_api_exception.dart';
import 'retry_after.dart';

/// Client for the Fluw backend API v1. One instance is shared by the whole
/// app so the "server is awake" state lasts for the session.
///
/// Never logs request URLs: they contain barcodes and search text.
class FluwApiClient {
  FluwApiClient({
    http.Client? httpClient,
    ApiConfig? config,
    this.timeouts = const ApiTimeouts(),
    DateTime Function()? now,
  }) : _http = httpClient ?? http.Client(),
       config = config ?? ApiConfig.fromEnvironment(),
       _now = now ?? DateTime.now;

  /// Longer server texts are replaced by the default message for the error.
  static const int maxServerMessageLength = 200;

  final ApiConfig config;
  final ApiTimeouts timeouts;
  final http.Client _http;
  final DateTime Function() _now;

  bool _serverAwake = false;

  /// True once the server has answered in this session. Until then requests
  /// get the longer cold-start budget.
  bool get isServerAwake => _serverAwake;

  /// Wakes the server up (Render cold start). Never throws.
  Future<bool> wakeUp({ApiCancelToken? cancelToken}) async {
    try {
      final http.Response response = await _send(
        config.endpoint(['health']),
        timeouts.health(serverAwake: _serverAwake),
        cancelToken,
      );
      final Map<String, dynamic>? body = _decode(response).object;
      final bool healthy =
          response.statusCode == 200 && body?['success'] == true;
      if (healthy) _serverAwake = true;
      return healthy;
    } on FluwApiException {
      return false;
    }
  }

  Future<SearchResults> search(
    String query, {
    ApiCancelToken? cancelToken,
  }) async {
    final Map<String, dynamic> body = await _getJson(
      config.endpoint(['api', 'v1', 'search'], {'q': query.trim()}),
      timeouts.search(serverAwake: _serverAwake),
      cancelToken,
    );
    return _parse(() => SearchResults.fromJson(body));
  }

  Future<ProductDetails> product(
    String barcode, {
    ApiCancelToken? cancelToken,
  }) async {
    final Map<String, dynamic> body = await _getJson(
      config.endpoint(['api', 'v1', 'products', barcode]),
      timeouts.product(serverAwake: _serverAwake),
      cancelToken,
    );
    return _parse(() => ProductDetails.fromJson(body));
  }

  /// Zero's explanation of the score. An AI failure is not an exception: it
  /// comes back as [ProductAnalysis.aiError].
  Future<ProductAnalysis> analysis(
    String barcode, {
    ApiCancelToken? cancelToken,
  }) async {
    final Map<String, dynamic> body = await _getJson(
      config.endpoint(['api', 'v1', 'products', barcode, 'analysis']),
      timeouts.analysis(serverAwake: _serverAwake),
      cancelToken,
    );
    return _parse(() => ProductAnalysis.fromJson(body));
  }

  void close() => _http.close();

  Future<Map<String, dynamic>> _getJson(
    Uri uri,
    Duration timeout,
    ApiCancelToken? cancelToken,
  ) async {
    final http.Response response = await _send(uri, timeout, cancelToken);
    final int status = response.statusCode;
    final _DecodedBody decoded = _decode(response);
    final Map<String, dynamic>? body = decoded.object;

    if (!decoded.isJson) {
      // An HTML or empty page from Render or Cloudflare, not from Fluw.
      throw FluwApiException(
        kind: ApiErrorKind.serverUnavailable,
        statusCode: status,
        retryAfter: _retryAfter(response),
      );
    }

    final bool isSuccessStatus = status >= 200 && status < 300;
    if (body != null && isSuccessStatus && body['success'] == true) {
      _serverAwake = true;
      return body;
    }
    if (body != null && (!isSuccessStatus || body['success'] == false)) {
      throw _errorFromBody(response, body);
    }
    throw FluwApiException(
      kind: ApiErrorKind.invalidResponse,
      statusCode: status,
    );
  }

  FluwApiException _errorFromBody(
    http.Response response,
    Map<String, dynamic> body,
  ) {
    final String? code = readString(body['code']);
    final ApiErrorKind kind =
        ApiErrorKind.fromCode(code) ??
        ApiErrorKind.fromStatus(response.statusCode);
    final String? serverMessage = readString(body['error']);
    final bool useServerMessage =
        serverMessage != null && serverMessage.length <= maxServerMessageLength;

    return FluwApiException(
      kind: kind,
      message: useServerMessage ? serverMessage : null,
      code: code,
      statusCode: response.statusCode,
      retryAfter: _retryAfter(response),
    );
  }

  Duration? _retryAfter(http.Response response) =>
      parseRetryAfter(response.headers['retry-after'], now: _now());

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw FluwApiException(
        kind: ApiErrorKind.invalidResponse,
        statusCode: 200,
      );
    }
  }

  /// Sends a GET that is aborted when [timeout] passes or [cancelToken] is
  /// cancelled. The race with the abort signal also covers clients that
  /// ignore `abortTrigger`.
  Future<http.Response> _send(
    Uri uri,
    Duration timeout,
    ApiCancelToken? cancelToken,
  ) async {
    if (cancelToken?.isCancelled ?? false) {
      throw FluwApiException(kind: ApiErrorKind.cancelled);
    }

    final Completer<void> abort = Completer<void>();
    ApiErrorKind? abortKind;
    void abortWith(ApiErrorKind kind) {
      if (abort.isCompleted) return;
      abortKind = kind;
      abort.complete();
    }

    final Timer timer = Timer(timeout, () => abortWith(ApiErrorKind.timeout));
    final void Function() stopListening =
        cancelToken?.onCancel(() => abortWith(ApiErrorKind.cancelled)) ?? () {};

    final http.AbortableRequest request = http.AbortableRequest(
      'GET',
      uri,
      abortTrigger: abort.future,
    )..headers['accept'] = 'application/json';

    try {
      return await Future.any<http.Response>([
        _http.send(request).then(http.Response.fromStream),
        abort.future.then<http.Response>((_) => throw const _Aborted()),
      ]);
    } on Exception {
      final ApiErrorKind? kind = abortKind;
      if (kind == ApiErrorKind.timeout) {
        // The free Render instance may have gone back to sleep; give the next
        // attempt the cold-start budget again.
        _serverAwake = false;
      }
      throw FluwApiException(kind: kind ?? ApiErrorKind.network);
    } finally {
      timer.cancel();
      stopListening();
    }
  }

  static _DecodedBody _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return const _DecodedBody.notJson();
    try {
      final Object? decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return _DecodedBody.json(
        decoded is Map<String, dynamic> ? decoded : null,
      );
    } on FormatException {
      return const _DecodedBody.notJson();
    }
  }
}

class _DecodedBody {
  const _DecodedBody.json(this.object) : isJson = true;

  const _DecodedBody.notJson() : object = null, isJson = false;

  final bool isJson;

  /// The decoded value when it is a JSON object.
  final Map<String, dynamic>? object;
}

class _Aborted implements Exception {
  const _Aborted();
}
