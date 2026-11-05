/// Build-time switches, set with `--dart-define`.
class FeatureFlags {
  const FeatureFlags._();

  /// When true, Zero's explanation loads by itself once the product is shown.
  /// Off by default: every explanation costs an AI call, so the user asks.
  static const bool zeroAutoLoad = bool.fromEnvironment('ZERO_AUTO_LOAD');
}
