import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/features/home/domain/day_evaluation.dart';

PersonalLimits _limits({bool watchesSaturatedFat = false, double? kcal = 2000}) => PersonalLimits(
  profileStatus: ProfileStatus.loaded,
  severeAllergenTags: const {},
  mildAllergenTags: const {},
  allergenNames: const {},
  dailyKcal: kcal,
  proteinMinG: 100,
  sugarsMaxG: 50,
  saturatedFatMaxG: 20,
  sodiumMaxMg: kcal == null ? null : 2000,
  watchesSugar: false,
  watchesSodium: false,
  watchesSaturatedFat: watchesSaturatedFat,
);

NutrientTotals _totals(List<Map<Nutrient, double>> foods) => NutrientTotals.of(foods.map(Nutrients.new));

void main() {
  test('ngày chưa ghi món thì không đánh giá (không bị coi là thiếu 2,000 kcal)', () {
    expect(evaluateDay(totals: _totals(const []), entryCount: 0, limits: _limits()).verdicts, isEmpty);
  });

  test('calo trong khoảng ±10% là đạt, so theo số kcal đã làm tròn như trên màn', () {
    VerdictStatus kcalStatus(double kcal) => evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: kcal, Nutrient.proteinG: 100, Nutrient.sugarsG: 10},
      ]),
      entryCount: 1,
      limits: _limits(),
    ).verdicts.first.status;

    expect(kcalStatus(1800), VerdictStatus.onTarget);
    expect(kcalStatus(1799.6), VerdictStatus.onTarget, reason: 'hiện là 1,800 kcal');
    expect(kcalStatus(2200.4), VerdictStatus.onTarget, reason: 'hiện là 2,200 kcal');
    expect(kcalStatus(1799), VerdictStatus.below);
    expect(kcalStatus(2201), VerdictStatus.over);
    expect(kcalStatus(2209), VerdictStatus.over, reason: '110.45%: % làm tròn là 110 nhưng 2,209 > 2,200 kcal');
  });

  test('protein: đủ khi đạt cận dưới (so theo 0,1 g); đường so theo 0,1 g như số hiện', () {
    DayEvaluation evaluate(double sugars) => evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: 2000, Nutrient.proteinG: 99.96, Nutrient.sugarsG: sugars, Nutrient.sodiumMg: 1500},
      ]),
      entryCount: 1,
      limits: _limits(),
    );

    final within = evaluate(50.04);
    expect(within.verdicts.map((verdict) => (verdict.nutrient, verdict.status)), [
      (Nutrient.energyKcal, VerdictStatus.onTarget),
      (Nutrient.proteinG, VerdictStatus.reached),
      (Nutrient.sugarsG, VerdictStatus.withinLimit),
      (Nutrient.sodiumMg, VerdictStatus.withinLimit),
    ]);
    expect(within.isBalanced, isTrue);

    final over = evaluate(50.06).verdicts[2];
    expect(over.status, VerdictStatus.over, reason: '100.1% làm tròn là 100% nhưng hiện 50.1 > 50 g');
    expect(over.gap, closeTo(0.1, 1e-9), reason: 'khoảng cách theo số hiện, không phải 0.06');
  });

  test('natri xét cho mọi người lớn có chỉ tiêu (WHO); béo bão hòa chỉ khi có mỡ máu cao; khoảng cách đúng', () {
    final evaluation = evaluateDay(
      totals: _totals([
        {Nutrient.energyKcal: 1500, Nutrient.proteinG: 60, Nutrient.sugarsG: 70, Nutrient.sodiumMg: 2600},
      ]),
      entryCount: 1,
      limits: _limits(),
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
      (Nutrient.sodiumMg, VerdictStatus.noData),
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
      VerdictStatus.noData,
    ]);
  });

  test('calo dưới 50% mục tiêu: có thể chưa ghi đủ món, không nói thiếu bao nhiêu', () {
    NutrientVerdict kcalVerdict(List<Map<Nutrient, double>> foods) =>
        evaluateDay(totals: _totals(foods), entryCount: foods.length, limits: _limits()).verdicts.first;

    final few = kcalVerdict([
      {Nutrient.energyKcal: 999},
    ]);
    expect(few.status, VerdictStatus.maybeUnderLogged);
    expect(few.gap, 0);
    expect(few.isGood, isFalse);
    expect(
      kcalVerdict([
        {Nutrient.energyKcal: 999.6},
      ]).status,
      VerdictStatus.below,
      reason: 'hiện là 1,000 kcal, đúng 50%',
    );
    expect(
      kcalVerdict([
        {Nutrient.energyKcal: 600},
        {Nutrient.proteinG: 10},
      ]).status,
      VerdictStatus.incomplete,
      reason: 'có món thiếu calo thì không kết luận',
    );
  });
}
