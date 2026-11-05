import '../../models/score/additives_score.dart';
import '../../models/score/fluw_score.dart';
import '../../models/score/nutrition_score.dart';
import '../../models/score/score_indicator.dart';
import 'vietnamese_number.dart';

/// Turns the numbers the backend sent into the sentences shown in the app.
/// Nothing here computes a score: every value comes from [FluwScore].
class ScoreFormat {
  const ScoreFormat._();

  static const String notEnoughData = 'Chưa đủ dữ liệu';

  /// "74/100".
  static String outOf100(int value) => '$value/100';

  /// 0.7 → "70%".
  static String weightPercent(double weight) =>
      '${formatVietnameseNumber(weight * 100, maxFractionDigits: 1)}%';

  /// 0.7 → "0,7".
  static String weight(double weight) =>
      formatVietnameseNumber(weight, maxFractionDigits: 3);

  static String nutritionValue(NutritionScore nutrition) {
    final int? value = nutrition.value;
    if (value != null) return outOf100(value);
    return nutrition.status == NutritionStatus.notApplicable
        ? 'Không áp dụng'
        : notEnoughData;
  }

  static String additivesValue(AdditivesScore additives) {
    final int? value = additives.value;
    return value == null ? notEnoughData : outOf100(value);
  }

  /// "Dinh dưỡng 80/100 · trọng số 70%".
  static String component(String name, String value, double? weight) {
    return weight == null
        ? '$name $value'
        : '$name $value · trọng số ${weightPercent(weight)}';
  }

  /// "80 × 0,7 + 60 × 0,3 = 74", or "… = 30,6 → 31" when the sum was rounded.
  /// Null when a number needed for the line is missing.
  static String? calculation(FluwScore score) {
    final int? total = score.total.value;
    final double? sum = score.total.calculation?.sum;
    final int? nutrition = score.nutrition.value;
    final int? additives = score.additives.value;
    final double? nutritionWeight = score.nutritionWeight;
    final double? additivesWeight = score.additivesWeight;
    if (total == null ||
        sum == null ||
        nutrition == null ||
        additives == null ||
        nutritionWeight == null ||
        additivesWeight == null) {
      return null;
    }

    final String terms =
        '$nutrition × ${weight(nutritionWeight)} + $additives × ${weight(additivesWeight)}';
    final String sumText = formatVietnameseNumber(sum, maxFractionDigits: 2);
    return sumText == '$total'
        ? '$terms = $total'
        : '$terms = $sumText → $total';
  }

  /// "2.000 kJ", "0,01 g", "40%", "0 chất".
  static String indicatorValue(double value, String? unit) {
    return switch (unit) {
      'kJ' => '${formatVietnameseNumber(value, maxFractionDigits: 1)} kJ',
      'g' => '${formatVietnameseNumber(value, maxFractionDigits: 2)} g',
      '%' => '${formatVietnameseNumber(value, maxFractionDigits: 2)}%',
      'count' => '${formatVietnameseNumber(value, maxFractionDigits: 0)} chất',
      null => formatVietnameseNumber(value, maxFractionDigits: 2),
      _ => '${formatVietnameseNumber(value, maxFractionDigits: 2)} $unit',
    };
  }

  /// "/100 g", "/100 ml" or "".
  static String per(String? per) {
    return switch (per) {
      '100g' => '/100 g',
      '100ml' => '/100 ml',
      _ => '',
    };
  }

  /// "2.000 kJ/100 g" or "Chưa có dữ liệu".
  static String indicatorMeasure(ScoreIndicator indicator) {
    final double? value = indicator.value;
    if (value == null) return 'Chưa có dữ liệu';
    return '${indicatorValue(value, indicator.unit)}${per(indicator.per)}';
  }

  /// "> 1.675 – ≤ 2.010 kJ", "≤ 3 g", "> 10 g". Null without bounds.
  static String? range(IndicatorRange? range, String? unit) {
    if (range == null) return null;
    final double? min = range.min;
    final double? max = range.max;
    // The backend compares with ">" unless told otherwise (SCORING.md §2.1).
    final String? lower = min == null
        ? null
        : '${range.minInclusive == true ? '≥' : '>'} ${_bound(min, unit)}';
    final String? upper = max == null
        ? null
        : '${range.maxInclusive == false ? '<' : '≤'} ${_bound(max, unit)}';
    final String? bounds = switch ((lower, upper)) {
      (final String l, final String u) => '$l – $u',
      (final String l, null) => l,
      (null, final String u) => u,
      (null, null) => null,
    };
    if (bounds == null) return null;
    return switch (unit) {
      '%' => '$bounds%',
      'kJ' || 'g' => '$bounds $unit',
      _ => bounds,
    };
  }

  static String _bound(double value, String? unit) {
    return formatVietnameseNumber(
      value,
      maxFractionDigits: unit == 'kJ' ? 1 : 2,
    );
  }

  /// "5/10 điểm".
  static String points(int? points, int? maxPoints) {
    if (points == null) return notEnoughData;
    return maxPoints == null ? '$points điểm' : '$points/$maxPoints điểm';
  }

  static String effect(IndicatorEffect? effect) {
    return switch (effect) {
      IndicatorEffect.negative => 'Điểm trừ',
      IndicatorEffect.positive => 'Điểm cộng',
      null => 'Chưa rõ chiều tính',
    };
  }

  static String indicatorStatus(IndicatorStatus? status) {
    return switch (status) {
      IndicatorStatus.counted => 'Đã tính',
      IndicatorStatus.excludedByRule => 'Không tính theo quy tắc',
      IndicatorStatus.estimated => 'Ước tính',
      null => 'Chưa rõ trạng thái',
    };
  }

  /// "19 … 55" (raw points). Open ends use "≤"/"≥".
  static String? pointsInterval(int? min, int? max) {
    String signed(int value) => formatVietnameseNumber(value);
    return switch ((min, max)) {
      (final int a, final int b) =>
        a == b ? signed(a) : '${signed(a)} … ${signed(b)}',
      (final int a, null) => '≥ ${signed(a)}',
      (null, final int b) => '≤ ${signed(b)}',
      (null, null) => null,
    };
  }

  /// "0–19" (a 0–100 score interval).
  static String? scoreInterval(int? min, int? max) {
    return switch ((min, max)) {
      (final int a, final int b) => a == b ? '$a' : '$a–$b',
      (final int a, null) => 'từ $a',
      (null, final int b) => 'đến $b',
      (null, null) => null,
    };
  }

  /// "3–4 phụ gia", "0 phụ gia", "từ 10 phụ gia trở lên".
  static String? additivesInterval(AdditivesBand band) {
    final int? min = band.countMin;
    final int? max = band.countMax;
    return switch ((min, max)) {
      (final int a, final int b) => a == b ? '$a phụ gia' : '$a–$b phụ gia',
      (final int a, null) => 'từ $a phụ gia trở lên',
      (null, final int b) => 'tối đa $b phụ gia',
      (null, null) => null,
    };
  }
}
