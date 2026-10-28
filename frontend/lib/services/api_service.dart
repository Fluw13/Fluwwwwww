import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'https://fluw.onrender.com/api/product';

  static Future<ProductModel> fetchProductByBarcode(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final requestUrl = Uri.parse('$baseUrl/$encodedQuery');
    final response = await http.get(requestUrl);

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return ProductModel.fromJson(responseData);
    } else {
      final errorMessage =
          responseData['error'] ?? 'Đã xảy ra lỗi không xác định từ máy chủ.';
      throw Exception(errorMessage.replaceAll('Exception: ', ''));
    }
  }
}
