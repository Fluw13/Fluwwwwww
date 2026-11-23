import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/core/widgets/nutrient_target_status.dart';

void main() {
  NutrientTargetStatus status(Nutrient nutrient, double? value, double? target, NutrientTargetKind kind) =>
      NutrientTargetStatus.of(nutrient: nutrient, value: value, target: target, kind: kind);

  test('mỗi loại chỉ tiêu giữ đúng chữ: mục tiêu, cần ít nhất, tối đa, mức gợi ý', () {
    expect(status(Nutrient.energyKcal, 1, 2, NutrientTargetKind.calorieGoal).targetWord, 'mục tiêu');
    expect(status(Nutrient.proteinG, 1, 2, NutrientTargetKind.minimum).targetWord, 'cần ít nhất');
    expect(status(Nutrient.sodiumMg, 1, 2, NutrientTargetKind.limit).targetWord, 'tối đa');
    expect(status(Nutrient.sugarsG, 1, 2, NutrientTargetKind.suggestion).targetWord, 'mức gợi ý');
    expect(status(Nutrient.fatG, 1, 2, NutrientTargetKind.target).targetWord, 'mục tiêu');
  });

  test('thiếu tổng hoặc chỉ tiêu thì không có % và không vẽ thanh', () {
    for (final candidate in [
      status(Nutrient.sodiumMg, null, 2000, NutrientTargetKind.limit),
      status(Nutrient.sodiumMg, 2500, null, NutrientTargetKind.limit),
    ]) {
      expect(candidate.percent, isNull);
      expect(candidate.share, isNull);
      expect(candidate.isOver, isFalse);
      expect(candidate.overText, isNull);
    }
  });

  test('protein vượt mức tối thiểu không phải cảnh báo; thanh dừng ở 100%', () {
    final protein = status(Nutrient.proteinG, 150, 100, NutrientTargetKind.minimum);

    expect(protein.percent, 150);
    expect(protein.share, 1);
    expect(protein.isOver, isFalse);
  });

  test('đường cao hơn mức gợi ý: màu cảnh báo, không phải màu lỗi; natri vượt: màu lỗi', () {
    final scheme = AppTheme.light().colorScheme;
    final sugars = status(Nutrient.sugarsG, 25.1, 25, NutrientTargetKind.suggestion);
    final sodium = status(Nutrient.sodiumMg, 2001, 2000, NutrientTargetKind.limit);

    expect(sugars.overText, 'Cao hơn mức gợi ý cả ngày.');
    expect(sugars.overColor(scheme), scheme.tertiary);
    expect(sodium.overText, 'Vượt giới hạn cả ngày.');
    expect(sodium.overColor(scheme), scheme.error);
  });
}
