// Responses in the shape the backend sends (CLAUDE.md "API tra cứu"); numbers taken from the backend's real
// Open Food Facts fixtures (Vinamilk strawberry yoghurt, Coca-Cola) and a USDA SR Legacy sample.

const Map<String, Object?> yoghurtSearchItem = {
  'id': 'off:8934673607827',
  'source': 'openFoodFacts',
  'name': 'Vinamilk sữa chua dâu',
  'brand': 'Vinamilk',
  'barcode': '8934673607827',
  'imageUrl': null,
  'servingSize': null,
  'basis': {'amount': 100, 'unit': 'g'},
  'nutrients': {
    'energyKcal': 99.4,
    'proteinG': 3,
    'carbohydratesG': 16,
    'sugarsG': 14.7,
    'fatG': 2.6,
    'saturatedFatG': null,
    'sodiumMg': 36,
  },
  'allergenTags': null,
  'attribution': {
    'source': 'Open Food Facts',
    'license': 'ODbL',
    'imageLicense': null,
    'url': 'https://world.openfoodfacts.org/product/8934673607827',
  },
};

final Map<String, Object?> yoghurtProduct = {
  ...yoghurtSearchItem,
  'servingSize': '1 portion (100 g)',
  'allergenTags': ['en:milk'],
};

const Map<String, Object?> colaItem = {
  'id': 'off:0049000004632',
  'source': 'openFoodFacts',
  'name': 'Coca-Cola',
  'brand': 'Coca-Cola',
  'barcode': '0049000004632',
  'imageUrl': 'https://images.openfoodfacts.org/images/products/004/900/000/4632/front_en.71.200.jpg',
  'servingSize': '1 bottle (355 ml)',
  'basis': {'amount': 100, 'unit': 'ml'},
  'nutrients': {
    'energyKcal': 42.25,
    'proteinG': 0,
    'carbohydratesG': 10.99,
    'sugarsG': 10.99,
    'fatG': 0,
    'saturatedFatG': 0,
    'sodiumMg': 23.94,
  },
  'allergenTags': <String>[],
  'attribution': {
    'source': 'Open Food Facts',
    'license': 'ODbL',
    'imageLicense': 'CC BY-SA',
    'url': 'https://world.openfoodfacts.org/product/0049000004632',
  },
};

const Map<String, Object?> chickenItem = {
  'id': 'usda:171477',
  'source': 'usda',
  'name': 'Chicken, broiler, breast, meat only, cooked, roasted',
  'brand': null,
  'barcode': null,
  'imageUrl': null,
  'servingSize': null,
  'basis': {'amount': 100, 'unit': 'g'},
  'nutrients': {
    'energyKcal': 165,
    'proteinG': 31.02,
    'carbohydratesG': 0,
    'sugarsG': 0,
    'fatG': 3.57,
    'saturatedFatG': 1.01,
    'sodiumMg': 74,
  },
  'allergenTags': null,
  'attribution': {
    'source': 'USDA FoodData Central',
    'license': 'CC0 1.0',
    'imageLicense': null,
    'url': 'https://fdc.nal.usda.gov/food-details/171477/nutrients',
  },
};

Map<String, Object?> searchBody(String query, List<Map<String, Object?>> items, {String usda = 'ok'}) => {
  'query': query,
  'items': items,
  'sources': {'openFoodFacts': 'ok', 'usda': usda},
};
