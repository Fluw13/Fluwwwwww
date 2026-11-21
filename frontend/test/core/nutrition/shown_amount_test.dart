import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';

void main() {
  test('kcal và mg hiện số nguyên, gam hiện 1 chữ số thập phân', () {
    expect(formatShownAmount(Nutrient.energyKcal, 2083.4), '2,083');
    expect(formatShownAmount(Nutrient.sodiumMg, 1250.6), '1,251');
    expect(formatShownAmount(Nutrient.sugarsG, 25.04), '25');
    expect(formatShownAmount(Nutrient.sugarsG, 25.06), '25.1');
  });

  test('vượt khi số hiện lớn hơn: 25.1 / 25 g là vượt dù % làm tròn là 100%; 25.04 / 25 g thì không', () {
    expect(isOverAsShown(Nutrient.sugarsG, amount: 25.1, target: 25), isTrue);
    expect(isOverAsShown(Nutrient.sugarsG, amount: 25.04, target: 25), isFalse);
    expect(isOverAsShown(Nutrient.sugarsG, amount: 25, target: 25), isFalse);
    expect(isOverAsShown(Nutrient.energyKcal, amount: 2090, target: 2083), isTrue, reason: '% làm tròn là 100%');
    expect(isOverAsShown(Nutrient.energyKcal, amount: 2083.4, target: 2083), isFalse);
    expect(isOverAsShown(Nutrient.sodiumMg, amount: 2000.4, target: 2000), isFalse);
    expect(isOverAsShown(Nutrient.sodiumMg, amount: 2000.5, target: 2000), isTrue);
  });

  test('thấp hơn theo số hiện: protein 99.96 g là đủ 100 g, 99.94 g thì chưa', () {
    expect(isBelowAsShown(Nutrient.proteinG, amount: 99.96, target: 100), isFalse);
    expect(isBelowAsShown(Nutrient.proteinG, amount: 99.94, target: 100), isTrue);
    expect(isBelowAsShown(Nutrient.energyKcal, amount: 999.6, target: 1000), isFalse);
  });

  test('khoảng chênh tính từ số hiện, nên "vượt" không bao giờ đi cùng "0"', () {
    expect(shownDifference(Nutrient.energyKcal, amount: 2083.6, target: 2083.4), 1);
    expect(shownDifference(Nutrient.sugarsG, amount: 25.06, target: 24.96), closeTo(0.1, 1e-9));
    expect(shownDifference(Nutrient.sodiumMg, amount: 1500, target: 2000), -500);
  });

  test('% khớp với kết luận vượt: trên 100% chỉ khi vượt, vượt thì không hiện 100%', () {
    expect(percentAsShown(Nutrient.sugarsG, amount: 25.1, target: 25), 101, reason: '100.4% nhưng 25.1 > 25 g');
    expect(percentAsShown(Nutrient.sugarsG, amount: 25.04, target: 25), 100);
    expect(percentAsShown(Nutrient.sugarsG, amount: 10.049, target: 9.96), 100, reason: '10 / 10 g, 100.9%');
    expect(percentAsShown(Nutrient.sodiumMg, amount: 3000, target: 2000), 150);
    expect(percentAsShown(Nutrient.energyKcal, amount: 500, target: 2000), 25);
  });
}
