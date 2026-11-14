import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_config.dart';
import 'package:http/http.dart' as http;

final apiClientProvider = Provider<ApiClient>((ref) {
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);
  return ApiClient(httpClient: httpClient, baseUri: Uri.parse(apiBaseUrl), timeout: apiTimeout);
});
