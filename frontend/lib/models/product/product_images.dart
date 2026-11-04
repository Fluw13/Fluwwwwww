import '../../core/network/trusted_image_url.dart';
import '../../data/json/json_fields.dart';

/// One photo in three sizes: [small] 200 px, [display] 400 px and the
/// original [full], which is only downloaded when the user zooms in.
class ProductImageSet {
  const ProductImageSet({this.small, this.display, this.full});

  /// Untrusted URLs are dropped; a set with no usable URL is null.
  static ProductImageSet? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    if (json == null) return null;

    final ProductImageSet set = ProductImageSet(
      small: trustedImageUrlOrNull(readString(json['small'])),
      display: trustedImageUrlOrNull(readString(json['display'])),
      full: trustedImageUrlOrNull(readString(json['full'])),
    );
    return set.preview == null && set.full == null ? null : set;
  }

  final String? small;
  final String? display;
  final String? full;

  /// Best size for a thumbnail.
  String? get preview => small ?? display;

  /// Largest size, for the zoom view.
  String? get largest => full ?? display ?? small;
}

class ProductImages {
  const ProductImages({this.front, this.ingredients, this.nutrition});

  factory ProductImages.fromJson(Map<String, dynamic>? json) {
    return ProductImages(
      front: ProductImageSet.tryParse(json?['front']),
      ingredients: ProductImageSet.tryParse(json?['ingredients']),
      nutrition: ProductImageSet.tryParse(json?['nutrition']),
    );
  }

  final ProductImageSet? front;
  final ProductImageSet? ingredients;
  final ProductImageSet? nutrition;
}
