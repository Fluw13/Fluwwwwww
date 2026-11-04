/// Score level as decided by the backend (`score.total.level`). The app never
/// derives a level from a number; the text shown is the backend's `label`.
enum ScoreLevel {
  good(legacyLabel: 'Tốt'),
  moderate(legacyLabel: 'Trung bình'),
  limit(legacyLabel: 'Kém');

  const ScoreLevel({required this.legacyLabel});

  /// Only for the legacy AI-scored screen; removed with it.
  final String legacyLabel;

  static ScoreLevel? fromCode(String? code) => switch (code) {
    'good' => good,
    'moderate' => moderate,
    'limit' => limit,
    _ => null,
  };

  /// Only for the legacy AI-scored screen; removed with it.
  static ScoreLevel fromScore(int score) {
    if (score >= 70) return good;
    if (score >= 40) return moderate;
    return limit;
  }
}
