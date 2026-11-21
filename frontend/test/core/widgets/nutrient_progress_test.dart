import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/core/widgets/nutrient_progress.dart';

void main() {
  final theme = AppTheme.light();

  Future<void> pump(WidgetTester tester, Nutrient nutrient, double value, double target, NutrientTargetKind kind) =>
      tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: NutrientProgress(
              nutrient: nutrient,
              label: 'Chỉ số',
              value: value,
              target: target,
              unit: nutrient == Nutrient.sodiumMg ? 'mg' : 'g',
              color: Colors.green,
              kind: kind,
            ),
          ),
        ),
      );

  Color? barColor(WidgetTester tester) =>
      tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).color;

  testWidgets('đường tổng là mức gợi ý: cao hơn thì báo màu cảnh báo, không phải màu lỗi, không nói "vượt giới hạn"', (
    tester,
  ) async {
    await pump(tester, Nutrient.sugarsG, 25.1, 25, NutrientTargetKind.suggestion);

    expect(find.text('25.1 g / mức gợi ý 25 g'), findsOneWidget);
    final warning = tester.widget<Text>(find.text('Cao hơn mức gợi ý cả ngày.'));
    expect(warning.style?.color, theme.colorScheme.tertiary);
    expect(barColor(tester), theme.colorScheme.tertiary);
    expect(find.textContaining('giới hạn'), findsNothing);
  });

  testWidgets('giới hạn (natri) vượt thì báo màu lỗi; bằng giới hạn như số hiện thì không báo', (tester) async {
    await pump(tester, Nutrient.sodiumMg, 2000.6, 2000, NutrientTargetKind.limit);
    expect(tester.widget<Text>(find.text('Vượt giới hạn cả ngày.')).style?.color, theme.colorScheme.error);
    expect(barColor(tester), theme.colorScheme.error);

    await pump(tester, Nutrient.sodiumMg, 2000.4, 2000, NutrientTargetKind.limit);
    expect(find.text('2,000 mg / tối đa 2,000 mg'), findsOneWidget);
    expect(find.text('Vượt giới hạn cả ngày.'), findsNothing);
    expect(barColor(tester), Colors.green);
  });

  testWidgets('so theo số hiện: 25.04 / 25 g không báo, 25.1 / 25 g báo dù % làm tròn là 100%', (tester) async {
    await pump(tester, Nutrient.sugarsG, 25.04, 25, NutrientTargetKind.suggestion);
    expect(find.text('25 g / mức gợi ý 25 g'), findsOneWidget);
    expect(find.text('Cao hơn mức gợi ý cả ngày.'), findsNothing);

    await pump(tester, Nutrient.energyKcal, 2090, 2083, NutrientTargetKind.calorieGoal);
    expect(find.text('Vượt mục tiêu calo cả ngày.'), findsOneWidget, reason: '2,090 > 2,083 kcal như số hiện');
  });
}
