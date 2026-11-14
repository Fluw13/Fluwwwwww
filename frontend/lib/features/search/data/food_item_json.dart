import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/food_attribution.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/search_response.dart';
import 'package:fluw/features/search/domain/source_status.dart';

// Keys of the backend contract (CLAUDE.md, "API tra cứu"). Written out so renaming a Dart enum never breaks parsing.
const Map<String, Nutrient> _nutrientKeys = {
  'energyKcal': Nutrient.energyKcal,
  'proteinG': Nutrient.proteinG,
  'carbohydratesG': Nutrient.carbohydratesG,
  'sugarsG': Nutrient.sugarsG,
  'fatG': Nutrient.fatG,
  'saturatedFatG': Nutrient.saturatedFatG,
  'sodiumMg': Nutrient.sodiumMg,
};
const Map<String, FoodSource> _sourceKeys = {'openFoodFacts': FoodSource.openFoodFacts, 'usda': FoodSource.usda};
const Map<String, QuantityUnit> _unitKeys = {'g': QuantityUnit.gram, 'ml': QuantityUnit.milliliter};
const Map<String, SourceStatus> _statusKeys = {
  'ok': SourceStatus.ok,
  'unavailable': SourceStatus.unavailable,
  'not_configured': SourceStatus.notConfigured,
};

/// Returns null when the item does not follow the contract (unknown source or unit, basis other than 100,
/// impossible numbers), so one bad item is dropped instead of breaking the whole list.
FoodItem? foodItemFromJson(Object? json) {
  if (json is! Map<String, Object?>) {
    return null;
  }
  final id = json['id'];
  final source = _sourceKeys[json['source']];
  final basis = json['basis'];
  final nutrients = json['nutrients'];
  final attribution = _attributionFromJson(json['attribution']);
  if (id is! String || source == null || basis is! Map<String, Object?> || nutrients is! Map<String, Object?>) {
    return null;
  }
  final unit = _unitKeys[basis['unit']];
  if (unit == null || basis['amount'] != 100 || attribution == null) {
    return null;
  }

  final values = <Nutrient, double>{};
  for (final MapEntry(key: key, value: nutrient) in _nutrientKeys.entries) {
    final value = nutrients[key];
    if (value is num) {
      if (!value.isFinite || value < 0) {
        return null;
      }
      values[nutrient] = value.toDouble();
    }
  }
  final allergenTags = json['allergenTags'];

  return FoodItem(
    id: id,
    source: source,
    name: _text(json['name']),
    brand: _text(json['brand']),
    barcode: _text(json['barcode']),
    imageUrl: _httpsUri(json['imageUrl']),
    servingSize: _text(json['servingSize']),
    facts: NutritionFacts(per100: Nutrients(values), unit: unit),
    allergenTags: allergenTags is List ? [for (final tag in allergenTags) ?_text(tag)] : null,
    attribution: attribution,
  );
}

SearchResponse searchResponseFromJson(Map<String, Object?> json) {
  final items = json['items'];
  final sources = json['sources'];
  final query = json['query'];
  return SearchResponse(
    query: query is String ? query : '',
    items: [
      if (items is List)
        for (final item in items) ?foodItemFromJson(item),
    ],
    sources: {
      if (sources is Map<String, Object?>)
        for (final MapEntry(:key, :value) in sources.entries)
          if ((_sourceKeys[key], _statusKeys[value]) case (final source?, final status?)) source: status,
    },
  );
}

FoodAttribution? _attributionFromJson(Object? json) {
  if (json is! Map<String, Object?>) {
    return null;
  }
  final source = _text(json['source']);
  final license = _text(json['license']);
  final url = _httpsUri(json['url']);
  if (source == null || license == null || url == null) {
    return null;
  }
  return FoodAttribution(source: source, license: license, imageLicense: _text(json['imageLicense']), url: url);
}

String? _text(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : null;

// Only https links are opened or loaded, so a bad source cannot point the app at another scheme.
Uri? _httpsUri(Object? value) {
  final uri = value is String ? Uri.tryParse(value) : null;
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty ? uri : null;
}
