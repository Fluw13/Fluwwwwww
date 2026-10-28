import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'https://fluw.onrender.com/api/product';

  static Future<ProductModel> fetchProductByBarcode(String barcode) async {
    final response = await http.get(Uri.parse('/'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductModel.fromJson(data);
    } else {
      throw Exception('Không tìm thấy thông tin sản phẩm trên hệ thống.');
    }
  }
}
