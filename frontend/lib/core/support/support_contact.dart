/// Support address, set at build time with `--dart-define=SUPPORT_EMAIL=...`.
/// Until the real address exists the app shows a clearly marked sample.
class SupportContact {
  const SupportContact._();

  static const String _configured = String.fromEnvironment('SUPPORT_EMAIL');
  static const String _sample = 'hotro@example.com';

  static String get email => _configured.isEmpty ? _sample : _configured;

  static bool get isSample => _configured.isEmpty;
}
