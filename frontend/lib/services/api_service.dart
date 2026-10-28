import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'https://fluw.onrender.com/api/product';

  static Future<ProductModel> fetchProductByBarcode(String query) async {
    final String encodedQuery = Uri.encodeComponent(query);
    final Uri requestUrl = Uri.parse('$baseUrl/$encodedQuery');

    try {
      final http.Response response = await http.get(requestUrl);
      final String responseBody = response.body.trim();

      if (responseBody.startsWith('<')) {
        throw Exception('Máy chủ Render đang trả về giao diện HTML thay vì dữ liệu JSON. Nguyên nhân do sai đường dẫn API hoặc máy chủ đang gặp lỗi 502.');
      }

      final Map<String, dynamic> responseData = jsonDecode(responseBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return ProductModel.fromJson(responseData);
      } else {
        final String errorMessage = responseData['error'] ?? 'Lỗi không xác định từ máy chủ.';
        throw Exception(errorMessage);
      }
    } catch (error) {
      throw Exception(error.toString().replaceAll('Exception: ', ''));
    }
  }
}
