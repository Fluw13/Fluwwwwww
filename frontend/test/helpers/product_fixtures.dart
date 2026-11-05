import 'package:frontend/models/product/product_details.dart';

import 'contract_fixtures.dart';

/// A product from a contract fixture (e.g. "product-food-complete"). [edit]
/// can change the raw JSON first, to test a case the fixtures do not cover.
ProductDetails productDetails(
  String fixture, {
  void Function(Map<String, dynamic> product, Map<String, dynamic> score)? edit,
}) {
  final Map<String, dynamic> body = ContractFixture.load(fixture).body;
  edit?.call(
    body['product'] as Map<String, dynamic>,
    body['score'] as Map<String, dynamic>,
  );
  return ProductDetails.fromJson(body);
}
