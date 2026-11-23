import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/core/widgets/nutrient_target_status.dart';
import 'package:fluw/features/note/presentation/nutrient_stat_box.dart';

void main() {
  final theme = AppTheme.light();

  Future<void> pump(WidgetTester tester, {required double? value, required double? target}) => tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: NutrientStatBox(
          nutrient: Nutrient.sugarsG,
          label: 'Đường tổng',
          value: value,
          target: target,
          unit: 'g',
          color: Colors.orange,
          kind: NutrientTargetKind.suggestion,
        ),
      ),
    ),
  );

  testWidgets('ô đường tổng giữ chữ "mức gợi ý" và %; cao hơn thì báo màu cảnh báo', (tester) async {
    await pump(tester, value: 30, target: 25);

    expect(find.text('30 / mức gợi ý 25 g'), findsOneWidget);
    expect(find.text('120%'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Cao hơn mức gợi ý cả ngày.')).style?.color, theme.colorScheme.tertiary);
    expect(
      tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).color,
      theme.colorScheme.tertiary,
    );
  });

  testWidgets('chưa có số liệu thì ghi "Chưa có dữ liệu", không có % và không vẽ thanh', (tester) async {
    await pump(tester, value: null, target: 25);

    expect(find.text('Chưa có dữ liệu / mức gợi ý 25 g'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
