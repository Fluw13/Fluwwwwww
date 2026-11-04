import '../../data/json/json_fields.dart';

/// Data the score could not be computed without, e.g. "Chất xơ".
class MissingItem {
  const MissingItem({required this.label, this.key});

  static MissingItem? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    final String? label = readString(json?['label']);
    if (label == null) return null;
    return MissingItem(label: label, key: readString(json?['key']));
  }

  final String label;
  final String? key;
}
