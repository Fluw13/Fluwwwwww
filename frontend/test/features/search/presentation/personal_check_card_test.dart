import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/features/search/domain/food_assessment.dart';
import 'package:fluw/features/search/presentation/personal_check_card.dart';

const PersonalLimits _limits = PersonalLimits(
  profileStatus: ProfileStatus.loaded,
  severeAllergenTags: {},
  mildAllergenTags: {},
  allergenNames: {},
  dailyKcal: 2000,
  proteinMinG: 100,
  sugarsMaxG: 25,
  saturatedFatMaxG: 20,
  sodiumMaxMg: 2000,
  watchesSugar: true,
  watchesSodium: false,
  watchesSaturatedFat: false,
);

void main() {
  final theme = AppTheme.light();

  Future<void> pump(WidgetTester tester, List<PortionShare> shares) => tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PersonalCheckCard(
            allergens: const AllergensUnknown(),
            shares: shares,
            limits: _limits,
            portionLabel: '200 g',
            isLoadingAllergens: false,
          ),
        ),
      ),
    ),
  );

  Color? colorOf(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('đường tổng cao hơn mức gợi ý (theo số hiện): 101%, màu cảnh báo, không phải màu lỗi', (tester) async {
    await pump(tester, [const PortionShare(nutrient: Nutrient.sugarsG, amount: 25.1, dailyLimit: 25, isWatched: true)]);

    expect(find.text('Đường tổng (mức gợi ý, bạn đang theo dõi)'), findsOneWidget);
    expect(colorOf(tester, '101% · 25.1/25 g'), theme.colorScheme.tertiary, reason: '100.4% nhưng 25.1 > 25 g');
    expect(colorOf(tester, 'Cao hơn mức gợi ý cả ngày.'), theme.colorScheme.tertiary);
    expect(find.textContaining('giới hạn'), findsNothing);
  });

  testWidgets('natri vượt giới hạn: màu lỗi; bằng giới hạn như số hiện thì 100% và không báo vượt', (tester) async {
    await pump(tester, [
      const PortionShare(nutrient: Nutrient.sodiumMg, amount: 2600, dailyLimit: 2000, isWatched: false),
    ]);
    expect(colorOf(tester, '130% · 2,600/2,000 mg'), theme.colorScheme.error);
    expect(colorOf(tester, 'Vượt giới hạn cả ngày.'), theme.colorScheme.error);

    await pump(tester, [
      const PortionShare(nutrient: Nutrient.sodiumMg, amount: 2000.4, dailyLimit: 2000, isWatched: false),
    ]);
    expect(find.text('100% · 2,000/2,000 mg'), findsOneWidget);
    expect(find.text('Vượt giới hạn cả ngày.'), findsNothing);
  });

  testWidgets(
    'một khẩu phần chiếm từ 50% chỉ số đang theo dõi thì tô màu; chỉ số không theo dõi mà chưa vượt thì không',
    (tester) async {
      await pump(tester, [
        const PortionShare(nutrient: Nutrient.sugarsG, amount: 12.5, dailyLimit: 25, isWatched: true),
        const PortionShare(nutrient: Nutrient.sodiumMg, amount: 1200, dailyLimit: 2000, isWatched: false),
      ]);

      expect(colorOf(tester, '50% · 12.5/25 g'), theme.colorScheme.tertiary);
      expect(
        colorOf(tester, '60% · 1,200/2,000 mg'),
        isNot(anyOf(theme.colorScheme.tertiary, theme.colorScheme.error)),
        reason: 'natri không theo dõi theo bệnh, chưa vượt',
      );
    },
  );
}
