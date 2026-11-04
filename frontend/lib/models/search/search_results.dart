import '../../core/network/trusted_image_url.dart';
import '../../data/json/json_fields.dart';

/// Body of `GET /api/v1/search`.
class SearchResults {
  const SearchResults({
    required this.query,
    required this.items,
    required this.total,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    if (json['results'] is! List) {
      throw const FormatException('Thiếu danh sách "results"');
    }
    final List<SearchResultItem> items = readList(
      json['results'],
      SearchResultItem.tryParse,
    );
    return SearchResults(
      query: readString(json['query']),
      items: items,
      total: readInt(json['total']) ?? items.length,
    );
  }

  /// The query as the server normalised it.
  final String? query;
  final List<SearchResultItem> items;
  final int total;

  bool get isEmpty => items.isEmpty;

  /// True when the server found no product matching every word and fell back
  /// to near matches.
  bool get isApproximate => items.any((item) => item.matchesAllWords == false);
}

class SearchResultItem {
  const SearchResultItem({
    required this.barcode,
    this.name,
    this.brand,
    this.quantity,
    this.imageUrl,
    this.matchesAllWords,
  });

  /// Items without a barcode cannot be opened, so they are dropped.
  static SearchResultItem? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    final String? barcode = readString(json?['barcode']);
    if (json == null || barcode == null) return null;

    return SearchResultItem(
      barcode: barcode,
      name: readString(json['name']),
      brand: readString(json['brand']),
      quantity: readString(json['quantity']),
      imageUrl: trustedImageUrlOrNull(readString(json['imageUrl'])),
      matchesAllWords: readBool(json['matchesAllWords']),
    );
  }

  final String barcode;
  final String? name;
  final String? brand;
  final String? quantity;
  final String? imageUrl;
  final bool? matchesAllWords;
}
