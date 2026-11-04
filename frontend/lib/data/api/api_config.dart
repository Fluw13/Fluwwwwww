/// Where the Fluw backend lives. Set at build time with
/// `--dart-define=API_ORIGIN=https://host[:port]`.
class ApiConfig {
  const ApiConfig._(this.origin);

  static const String defaultOrigin = 'https://fluw.onrender.com';

  static const String _originDefine = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: defaultOrigin,
  );

  final Uri origin;

  factory ApiConfig.fromEnvironment() => ApiConfig.parse(_originDefine);

  /// Accepts only a bare origin (scheme, host and optional port) so request
  /// paths are always built from known segments.
  factory ApiConfig.parse(String raw) {
    final Uri? uri = Uri.tryParse(raw.trim());
    final bool isOrigin =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        (uri.path.isEmpty || uri.path == '/') &&
        !uri.hasQuery &&
        !uri.hasFragment;
    if (!isOrigin) {
      throw ArgumentError.value(
        raw,
        'API_ORIGIN',
        'Cần dạng https://tên-miền[:cổng], không kèm đường dẫn',
      );
    }
    return ApiConfig._(
      Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      ),
    );
  }

  Uri endpoint(
    List<String> pathSegments, [
    Map<String, String>? queryParameters,
  ]) {
    return Uri(
      scheme: origin.scheme,
      host: origin.host,
      port: origin.hasPort ? origin.port : null,
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
  }
}
