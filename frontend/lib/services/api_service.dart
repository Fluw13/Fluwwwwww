import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  static String baseUrl = 'https://fluw.onrender.com/api/product';

  static Future<ProductDetailResponse?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$baseUrl/barcode/$barcode');
      final response = await http.get(url).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(utf8.decode(response.bodyBytes));
        if (jsonBody['success'] == true) {
          return ProductDetailResponse.fromJson(jsonBody);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService Error] getProductByBarcode: $e');
      return null;
    }
  }

  static Future<List<SearchResultItem>> searchProducts(String keyword) async {
    try {
      final url = Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(keyword)}');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(utf8.decode(response.bodyBytes));
        if (jsonBody['success'] == true && jsonBody['data'] is List) {
          final List items = jsonBody['data'];
          return items.map((item) => SearchResultItem.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[ApiService Error] searchProducts: $e');
      return [];
    }
  }
}
