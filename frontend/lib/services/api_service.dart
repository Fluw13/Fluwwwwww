import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiException implements Exception {
  final String userMessage;
  final String? debugDetail;

  const ApiException(this.userMessage, {this.debugDetail});

  @override
  String toString() => userMessage;
}

class ApiService {
  static const String baseUrl = 'https://fluw.onrender.com/api/product';
  static const Duration requestTimeout = Duration(seconds: 20);
  static const String _genericErrorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';

  static Future<ProductModel> fetchProductByBarcode(String query) async {
    final Uri requestUrl = Uri.parse('$baseUrl/${Uri.encodeComponent(query)}');
    final http.Response response = await _get(requestUrl);
    final Map<String, dynamic>? responseData = _decodeJsonObject(response.body);

    if (responseData == null) {
      throw ApiException(
        'Máy chủ đang tạm thời gián đoạn. Vui lòng thử lại sau ít phút.',
        debugDetail: 'HTTP ${response.statusCode}: response body is not a JSON object',
      );
    }

    if (response.statusCode == 200 && responseData['success'] == true) {
      return ProductModel.fromJson(responseData);
    }

    final dynamic serverMessage = responseData['error'];
    throw ApiException(
      serverMessage is String && serverMessage.isNotEmpty ? serverMessage : _genericErrorMessage,
      debugDetail: 'HTTP ${response.statusCode}, code: ${responseData['code']}',
    );
  }

  static Future<http.Response> _get(Uri url) async {
    try {
      return await http.get(url).timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'Máy chủ phản hồi quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.',
        debugDetail: 'Request timed out after 20 seconds',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        'Không thể kết nối tới máy chủ Fluw. Vui lòng kiểm tra kết nối mạng.',
        debugDetail: error.toString(),
      );
    } catch (error) {
      throw ApiException(_genericErrorMessage, debugDetail: error.toString());
    }
  }

  static Map<String, dynamic>? _decodeJsonObject(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
