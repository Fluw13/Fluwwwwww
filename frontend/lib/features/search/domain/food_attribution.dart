/// Where the numbers come from, shown under every food as the data licenses require.
final class FoodAttribution {
  const FoodAttribution({required this.source, required this.license, required this.imageLicense, required this.url});

  final String source;
  final String license;
  final String? imageLicense;

  /// Null for a product the user typed in: there is no page to link to.
  final Uri? url;
}
