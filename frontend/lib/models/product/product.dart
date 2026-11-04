import '../../data/json/json_fields.dart';
import 'product_images.dart';
import 'product_nutrition.dart';
import 'product_source.dart';
import 'product_tags.dart';

/// `product` from `GET /api/v1/products/:barcode`. Every field except the
/// barcode may be missing; the UI shows that rather than guessing.
class Product {
  const Product({
    required this.barcode,
    this.name,
    this.genericName,
    this.brand,
    this.quantity,
    this.brandOwner,
    this.manufacturingPlaces,
    this.images = const ProductImages(),
    this.ingredientsText,
    this.ingredientsLanguage,
    this.allergens = const [],
    this.traces = const [],
    this.additives = const [],
    this.novaGroup,
    this.nutrition = const ProductNutrition(),
    this.source = const ProductSource(),
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? manufacturer = readMap(json['manufacturer']);
    final Map<String, dynamic>? ingredients = readMap(json['ingredients']);
    final int? nova = readInt(json['novaGroup']);

    return Product(
      barcode: requireString(json, 'barcode'),
      name: readString(json['name']),
      genericName: readString(json['genericName']),
      brand: readString(json['brand']),
      quantity: readString(json['quantity']),
      brandOwner: readString(manufacturer?['brandOwner']),
      manufacturingPlaces: readString(manufacturer?['manufacturingPlaces']),
      images: ProductImages.fromJson(readMap(json['images'])),
      ingredientsText: readString(ingredients?['text']),
      ingredientsLanguage: readString(ingredients?['language']),
      allergens: readList(json['allergens'], ProductTag.tryParse),
      traces: readList(json['traces'], ProductTag.tryParse),
      additives: readList(json['additives'], ProductAdditive.tryParse),
      novaGroup: nova != null && nova >= 1 && nova <= 4 ? nova : null,
      nutrition: ProductNutrition.fromJson(readMap(json['nutrition'])),
      source: ProductSource.fromJson(readMap(json['source'])),
    );
  }

  final String barcode;
  final String? name;
  final String? genericName;
  final String? brand;
  final String? quantity;
  final String? brandOwner;
  final String? manufacturingPlaces;
  final ProductImages images;
  final String? ingredientsText;
  final String? ingredientsLanguage;
  final List<ProductTag> allergens;

  /// "May contain" traces.
  final List<ProductTag> traces;
  final List<ProductAdditive> additives;

  /// NOVA processing group 1–4, shown for reference only, never scored.
  final int? novaGroup;
  final ProductNutrition nutrition;
  final ProductSource source;
}
