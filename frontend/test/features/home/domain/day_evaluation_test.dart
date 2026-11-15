import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/features/home/domain/day_evaluation.dart';

PersonalLimits _limits({bool watchesSodium = false, bool watchesSaturatedFat = false, double? kcal = 2000}) =>
    PersonalLimits(
      profileStatus: ProfileStatus.loaded,
      severeAllergenTags: const {},
      mildAllergenTags: const {},
      allergenNames: const {},
      dailyKcal: kcal,
      proteinMinG: 100,
      sugarsMaxG: 50,
      saturatedFatMaxG: 20,
      sodiumMaxMg: 2000,
      watchesSugar: false,
      watchesSodium: watchesSodium,
      watchesSaturatedFat: watchesSaturatedFat,
    );

NutrientTotals _totals(List<Map<Nutrient, double>> foods) => NutrientTotals.of(foods.map(Nutrients.new));

void main() {
  test('ngày chưa ghi món thì không đánh giá (không bị coi là thiếu 2,000 kcal)', () {
    expect(evaluateDay(totals: _totals(const []), entryCount: 0, limits: _limits()).verdicts, isEmpty);
  });

  test('calo trong khoảng ±10% là đạt; 89% là thấp; 111% là vượt (theo % đã làm tròn)', () {
    VerdictStatus kcalStatus(double kcal) => evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: kcal, Nutrient.proteinG: 100, Nutrient.sugarsG: 10},
      ]),
      entryCount: 1,
      limits: _limits(),
    ).verdicts.first.status;

    expect(kcalStatus(1800), VerdictStatus.onTarget);
    expect(kcalStatus(2200), VerdictStatus.onTarget);
    expect(kcalStatus(2209), VerdictStatus.onTarget, reason: '110.45% làm tròn thành 110%');
    expect(kcalStatus(1780), VerdictStatus.below);
    expect(kcalStatus(2220), VerdictStatus.over);
  });

  test('protein: đủ khi đạt cận dưới (so theo 0,1 g); đường 100,4% làm tròn thành 100% vẫn trong giới hạn', () {
    final evaluation = evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: 2000, Nutrient.proteinG: 99.96, Nutrient.sugarsG: 50.2},
      ]),
      entryCount: 1,
      limits: _limits(),
    );

    expect(evaluation.verdicts.map((verdict) => (verdict.nutrient, verdict.status)), [
      (Nutrient.energyKcal, VerdictStatus.onTarget),
      (Nutrient.proteinG, VerdictStatus.reached),
      (Nutrient.sugarsG, VerdictStatus.withinLimit),
    ]);
    expect(evaluation.isBalanced, isTrue);
  });

  test('thiếu và vượt có khoảng cách đúng; natri và béo bão hòa chỉ xét khi đang theo dõi', () {
    final evaluation = evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: 1500, Nutrient.proteinG: 60, Nutrient.sugarsG: 70, Nutrient.sodiumMg: 2600},
      ]),
      entryCount: 1,
      limits: _limits(watchesSodium: true),
    );

    expect(evaluation.verdicts.map((verdict) => (verdict.nutrient, verdict.status, verdict.gap)), [
      (Nutrient.energyKcal, VerdictStatus.below, 500),
      (Nutrient.proteinG, VerdictStatus.below, 40),
      (Nutrient.sugarsG, VerdictStatus.over, 20),
      (Nutrient.sodiumMg, VerdictStatus.over, 600),
    ]);
    expect(evaluation.isBalanced, isFalse);
  });

  test('món nào cũng thiếu một chỉ số thì là chưa có dữ liệu, không phải 0; có món thiếu thì báo', () {
    final evaluation = evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: 2000, Nutrient.proteinG: 120},
        {Nutrient.energyKcal: 50},
      ]),
      entryCount: 2,
      limits: _limits(watchesSaturatedFat: true),
    );

    final bySugar = evaluation.verdicts.firstWhere((verdict) => verdict.nutrient == Nutrient.sugarsG);
    expect(bySugar.status, VerdictStatus.noData);
    expect(
      evaluation.verdicts.firstWhere((verdict) => verdict.nutrient == Nutrient.saturatedFatG).status,
      VerdictStatus.noData,
    );
    expect(evaluation.hasMissingData, isTrue);
    expect(evaluation.isBalanced, isFalse);
  });

  test('không có mục tiêu calo (dưới 18 tuổi) thì chỉ xét những gì có chỉ tiêu', () {
    final evaluation = evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: 900, Nutrient.proteinG: 30, Nutrient.sugarsG: 5},
      ]),
      entryCount: 1,
      limits: _limits(kcal: null),
    );

    expect(evaluation.verdicts.map((verdict) => verdict.nutrient), [Nutrient.proteinG, Nutrient.sugarsG]);
  });

  test('thiếu số liệu ở vài món: "trong giới hạn", "đạt", "thiếu" thành chưa đủ số liệu; "vượt" và "đủ" vẫn đứng', () {
    final evaluation = evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: 1900, Nutrient.proteinG: 120, Nutrient.sugarsG: 5},
        {Nutrient.energyKcal: 100},
      ]),
      entryCount: 2,
      limits: _limits(),
    );

    expect(evaluation.verdicts.map((verdict) => (verdict.nutrient, verdict.status)), [
      (Nutrient.energyKcal, VerdictStatus.onTarget),
      (Nutrient.proteinG, VerdictStatus.reached),
      (Nutrient.sugarsG, VerdictStatus.incomplete),
    ]);
    expect(evaluation.isBalanced, isFalse, reason: 'đường chưa biết đủ thì không kết luận cân đối');

    final over = evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: 2500, Nutrient.proteinG: 40, Nutrient.sugarsG: 60},
        {Nutrient.energyKcal: 100},
      ]),
      entryCount: 2,
      limits: _limits(),
    );
    expect(over.verdicts.map((verdict) => verdict.status), [
      VerdictStatus.over,
      VerdictStatus.incomplete,
      VerdictStatus.over,
    ]);
  });
}
