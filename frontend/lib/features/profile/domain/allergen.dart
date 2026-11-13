/// The 14 allergen groups Open Food Facts tags products with (`allergens_tags`), so a saved allergy can be matched
/// against product data. Allergies outside this list are kept as a note only.
enum Allergen {
  gluten('en:gluten'),
  crustaceans('en:crustaceans'),
  eggs('en:eggs'),
  fish('en:fish'),
  peanuts('en:peanuts'),
  soybeans('en:soybeans'),
  milk('en:milk'),
  treeNuts('en:nuts'),
  celery('en:celery'),
  mustard('en:mustard'),
  sesame('en:sesame-seeds'),
  sulphites('en:sulphur-dioxide-and-sulphites'),
  lupin('en:lupin'),
  molluscs('en:molluscs');

  const Allergen(this.openFoodFactsTag);

  final String openFoodFactsTag;
}

enum AllergySeverity { severe, mild }
