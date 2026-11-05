/// Score level as decided by the backend (`score.total.level`). The app never
/// derives a level from a number; the text shown is the backend's `label`.
enum ScoreLevel {
  good,
  moderate,
  limit;

  static ScoreLevel? fromCode(String? code) => switch (code) {
    'good' => good,
    'moderate' => moderate,
    'limit' => limit,
    _ => null,
  };
}
