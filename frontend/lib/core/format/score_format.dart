/// Fluw Nutrition Score in Vietnamese number style: always one decimal, "," as separator ("7,8").
class ScoreFormat {
  const ScoreFormat._();

  static String fns(double score) => score.toStringAsFixed(1).replaceAll('.', ',');
}
