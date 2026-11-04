/// Product photos are only loaded over https from Open Food Facts, so a
/// tampered or unexpected URL never makes the app fetch from another host.
bool isTrustedImageUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;

  final String host = uri.host.toLowerCase();
  return host == 'openfoodfacts.org' || host.endsWith('.openfoodfacts.org');
}
