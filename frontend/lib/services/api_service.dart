import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fluw.onrender.com/api/product',
  );

  static const Duration _timeout = Duration(seconds: 60);

  final http.Client _client;

  Future<ProductModel> fetchProduct(String query) async {
    final Uri url = Uri.parse('$_baseUrl/${Uri.encodeComponent(query)}');
    final http.Response response = await _get(url);
    final Map<String, dynamic> body = _decodeBody(response);

    if (response.statusCode != 200 || body['success'] != true) {
      throw ApiException(body['error'] as String? ?? 'Máy chủ gặp lỗi không xác định.');
    }

    try {
      return ProductModel.fromJson(body);
    } on FormatException {
      throw const ApiException('Dữ liệu phân tích không hợp lệ. Vui lòng thử lại.');
    }
  }

  void dispose() => _client.close();

  Future<http.Response> _get(Uri url) async {
    try {
      return await _client.get(url).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on http.ClientException {
      throw const ApiException('Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.');
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      decoded = null;
    }

    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Máy chủ trả về dữ liệu không hợp lệ. Vui lòng thử lại sau.');
  }
}
