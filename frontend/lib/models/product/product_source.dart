import '../../data/json/json_fields.dart';

/// Where the product data comes from and under which licences.
class ProductSource {
  const ProductSource({
    this.provider,
    this.url,
    this.license,
    this.imagesLicense,
    this.lastModified,
    this.fetchedAt,
  });

  factory ProductSource.fromJson(Map<String, dynamic>? json) {
    return ProductSource(
      provider: readString(json?['provider']),
      url: _httpsUrlOrNull(readString(json?['url'])),
      license: readString(json?['license']),
      imagesLicense: readString(json?['imagesLicense']),
      lastModified: readDateTime(json?['lastModified']),
      fetchedAt: readDateTime(json?['fetchedAt']),
    );
  }

  final String? provider;

  /// Product page on Open Food Facts, offered to the user as a copyable link.
  final String? url;
  final String? license;
  final String? imagesLicense;

  /// Last edit of the product on Open Food Facts.
  final DateTime? lastModified;
  final DateTime? fetchedAt;

  static String? _httpsUrlOrNull(String? value) {
    final Uri? uri = value == null ? null : Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? value
        : null;
  }
}
