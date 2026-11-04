/// Product photos are only loaded over https from the two Open Food Facts
/// image hosts named in the API contract, so a tampered or unexpected URL
/// never makes the app fetch from another host.
const Set<String> trustedImageHosts = {
  'images.openfoodfacts.org',
  'static.openfoodfacts.org',
};

bool isTrustedImageUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
    return false;
  }
  if (uri.hasPort && uri.port != 443) return false;
  return trustedImageHosts.contains(uri.host.toLowerCase());
}

/// Returns [value] when it is a trusted image URL, otherwise null.
String? trustedImageUrlOrNull(String? value) =>
    value != null && isTrustedImageUrl(value) ? value : null;
