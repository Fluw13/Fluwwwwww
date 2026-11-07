/// Band of a Fluw Nutrition Score (0-10). Labels describe the score, not the product, so the app never
/// calls a product "good" or "bad" in absolute terms.
enum ScoreLevel {
  good(label: 'Cao'),
  moderate(label: 'Trung bình'),
  poor(label: 'Thấp');

  const ScoreLevel({required this.label});

  final String label;

  /// 6.7 and above matches reference rating 3.5 and above; below 3.3 matches 1.5 and below.
  static ScoreLevel fromScore(double score) {
    if (score >= 6.7) return good;
    if (score >= 3.3) return moderate;
    return poor;
  }
}
