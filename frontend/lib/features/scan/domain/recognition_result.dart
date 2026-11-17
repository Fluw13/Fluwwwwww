/// A food the vision model named in a photo. Only names and search terms: the nutrition always comes from the food
/// sources, never from the model.
final class RecognizedFood {
  const RecognizedFood({required this.name, required this.searchQuery, required this.englishQuery});

  final String name;
  final String searchQuery;

  /// English words for USDA, whose food names are English only; null when the model gave none.
  final String? englishQuery;

  @override
  bool operator ==(Object other) =>
      other is RecognizedFood &&
      other.name == name &&
      other.searchQuery == searchQuery &&
      other.englishQuery == englishQuery;

  @override
  int get hashCode => Object.hash(name, searchQuery, englishQuery);
}

final class RecognitionResult {
  RecognitionResult({required List<RecognizedFood> foods}) : foods = List.unmodifiable(foods);

  final List<RecognizedFood> foods;

  bool get isFood => foods.isNotEmpty;
}
