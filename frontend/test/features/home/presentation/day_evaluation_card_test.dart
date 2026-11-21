import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/features/home/domain/day_evaluation.dart';
import 'package:fluw/features/home/presentation/day_evaluation_card.dart';

NutrientVerdict _verdict(Nutrient nutrient, VerdictStatus status, {double eaten = 0, double target = 0}) =>
    NutrientVerdict(nutrient: nutrient, status: status, eaten: eaten, target: target, missingCount: 0);

void main() {
  final theme = AppTheme.light();

  Future<void> pump(WidgetTester tester, List<NutrientVerdict> verdicts) => tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: DayEvaluationCard(title: 'Đánh giá hôm qua', evaluation: DayEvaluation(verdicts)),
      ),
    ),
  );

  test('đường tổng là mức gợi ý; calo đạt ghi rõ ±10%; carb gọi là "Carb (bột đường)"', () {
    expect(
      verdictText(_verdict(Nutrient.sugarsG, VerdictStatus.over, eaten: 30, target: 26.04)),
      'Đường tổng: cao hơn mức gợi ý 4 g',
    );
    expect(verdictText(_verdict(Nutrient.sugarsG, VerdictStatus.withinLimit)), 'Đường tổng: trong mức gợi ý');
    expect(
      verdictText(_verdict(Nutrient.sodiumMg, VerdictStatus.over, eaten: 2600, target: 2000)),
      'Natri: vượt giới hạn 600 mg',
    );
    expect(verdictText(_verdict(Nutrient.energyKcal, VerdictStatus.onTarget)), 'Năng lượng: đạt mục tiêu (±10%)');
    expect(verdictText(_verdict(Nutrient.carbohydratesG, VerdictStatus.noData)), 'Carb (bột đường): chưa có dữ liệu');
  });

  test('calo dưới 50% mục tiêu: nói có thể chưa ghi đủ món, không nói thiếu bao nhiêu', () {
    final text = verdictText(_verdict(Nutrient.energyKcal, VerdictStatus.maybeUnderLogged, eaten: 640.4, target: 2000));

    expect(text, 'Năng lượng: có thể chưa ghi đủ món (mới ghi 640 kcal)');
    expect(text, isNot(contains('thấp hơn')));
  });

  testWidgets('đạt hết: "Đạt các chỉ tiêu Fluw đang theo dõi", không nói ăn cân đối', (tester) async {
    await pump(tester, [
      _verdict(Nutrient.energyKcal, VerdictStatus.onTarget),
      _verdict(Nutrient.sugarsG, VerdictStatus.withinLimit),
    ]);

    expect(find.text('Đạt các chỉ tiêu Fluw đang theo dõi.'), findsOneWidget);
    expect(find.textContaining('cân đối'), findsNothing);
  });

  testWidgets('đường cao hơn mức gợi ý: icon màu cảnh báo; natri vượt: màu lỗi; có thể chưa ghi đủ: icon thông tin', (
    tester,
  ) async {
    await pump(tester, [
      _verdict(Nutrient.energyKcal, VerdictStatus.maybeUnderLogged, eaten: 600, target: 2000),
      _verdict(Nutrient.sugarsG, VerdictStatus.over, eaten: 30, target: 26),
      _verdict(Nutrient.sodiumMg, VerdictStatus.over, eaten: 2600, target: 2000),
    ]);

    expect(find.text('Một số chỉ tiêu chưa đạt:'), findsOneWidget);
    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons.map((icon) => (icon.icon, icon.color)), [
      (Icons.info_outline, theme.colorScheme.onSurfaceVariant),
      (Icons.error_outline, theme.colorScheme.tertiary),
      (Icons.error_outline, theme.colorScheme.error),
    ]);
  });
}
