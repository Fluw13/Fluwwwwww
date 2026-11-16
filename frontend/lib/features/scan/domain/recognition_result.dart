/// A food the vision model named in a photo. Only a name and a search term: the nutrition always comes from the food
/// sources, never from the model.
final class RecognizedFood {
  const RecognizedFood({required this.name, required this.searchQuery});

  final String name;
  final String searchQuery;

  @override
  bool operator ==(Object other) => other is RecognizedFood && other.name == name && other.searchQuery == searchQuery;

  @override
  int get hashCode => Object.hash(name, searchQuery);
}

final class RecognitionResult {
  RecognitionResult({required List<RecognizedFood> foods}) : foods = List.unmodifiable(foods);

  final List<RecognizedFood> foods;

  bool get isFood => foods.isNotEmpty;
}
