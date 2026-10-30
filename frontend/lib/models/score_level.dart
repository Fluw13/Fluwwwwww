enum ScoreLevel {
  good(label: 'Tốt'),
  moderate(label: 'Trung bình'),
  poor(label: 'Kém');

  const ScoreLevel({required this.label});

  final String label;

  static ScoreLevel fromScore(int score) {
    if (score >= 70) return good;
    if (score >= 40) return moderate;
    return poor;
  }
}
