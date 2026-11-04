import '../../data/json/json_fields.dart';

/// A declared allergen or a "may contain" trace.
class ProductTag {
  const ProductTag({required this.label, this.tag});

  static ProductTag? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    final String? label =
        readString(json?['label']) ?? readString(json?['tag']);
    if (label == null) return null;
    return ProductTag(label: label, tag: readString(json?['tag']));
  }

  final String label;
  final String? tag;
}

class ProductAdditive {
  const ProductAdditive({required this.code, this.name, this.tag});

  static ProductAdditive? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    final String? code = readString(json?['code']);
    if (code == null) return null;
    return ProductAdditive(
      code: code,
      name: readString(json?['name']),
      tag: readString(json?['tag']),
    );
  }

  /// E-number such as "E471".
  final String code;
  final String? name;
  final String? tag;
}
