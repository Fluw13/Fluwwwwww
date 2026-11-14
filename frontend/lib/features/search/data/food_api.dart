import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/search/data/food_item_json.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/search_response.dart';

final class FoodApi {
  FoodApi(this._client);

  final ApiClient _client;

  Future<SearchResponse> search(String query) async =>
      searchResponseFromJson(await _client.getJson('/api/foods/search', query: {'q': query}));

  /// Returns null when the backend does not know the barcode, or rejects it as malformed (some Open Food Facts
  /// entries carry codes that fail the GTIN check); retrying would never help in either case.
  Future<FoodItem?> lookUpBarcode(String barcode) async {
    final Map<String, Object?> json;
    try {
      json = await _client.getJson('/api/foods/barcode/${Uri.encodeComponent(barcode)}');
    } on ServerFailure catch (failure) {
      if (failure.code == 'PRODUCT_NOT_FOUND' || failure.code == 'INVALID_BARCODE') {
        return null;
      }
      rethrow;
    }
    final item = foodItemFromJson(json['item']);
    if (item == null) {
      throw const InvalidResponseFailure();
    }
    return item;
  }
}
