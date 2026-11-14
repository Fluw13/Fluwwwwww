/// Where the numbers come from, shown under every food as the data licenses require.
final class FoodAttribution {
  const FoodAttribution({required this.source, required this.license, required this.imageLicense, required this.url});

  final String source;
  final String license;
  final String? imageLicense;
  final Uri url;
}
