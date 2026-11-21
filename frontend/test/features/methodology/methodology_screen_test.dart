import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/shell/fluw_bottom_bar.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/fluw_thresholds.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/features/methodology/presentation/methodology_content.dart';
import 'package:fluw/features/methodology/presentation/methodology_screen.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/nutrient_targets.dart';
import 'package:fluw/features/profile/domain/protein_target.dart';
import 'package:fluw/features/profile/domain/reference_weight.dart';

import '../../helpers/load_app_fonts.dart';
import '../../helpers/pump_fluw_app.dart';
import '../profile/domain/profile_fixture.dart';

void main() {
  final allText = [
    for (final section in methodologySections) ...[
      section.title,
      for (final item in section.items) ...[item.title, item.text, ...item.sources],
    ],
  ].join('\n');

  Future<void> openProfileTab(WidgetTester tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    final list = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical).hitTestable();
    final element = list.evaluate().first;
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byElementPredicate((e) => identical(e, element)),
      maxScrolls: 500,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  test('ghi nguồn của mọi công thức, đúng tên nghiên cứu', () {
    for (final source in [
      'Mifflin MD, St Jeor ST',
      'NHLBI (2005), Your Guide to Lowering Your Cholesterol with TLC',
      'Hector AJ, Phillips SM (2018)',
      'Morton RW và cs. (2018)',
      'Jäger R và cs. (2017)',
      'Institute of Medicine (2005)',
      'WHO (2015), Guideline: Sugars intake',
      'WHO (2012), Guideline: Sodium intake',
      'WHO (2023), Saturated fatty acid',
      'ATP III',
      'EFSA (2010)',
      'WHO khu vực Tây Thái Bình Dương (2000)',
    ]) {
      expect(allText, contains(source));
    }
    expect(allText, contains('Khi mức tối thiểu bằng hoặc cao hơn TDEE, mục tiêu giữ bằng TDEE'));
    expect(allText, contains('35 ml/kg là mức Fluw chọn'));
    expect(allText, contains('Carb (bột đường)'));
    expect(allText, contains('Đường tổng (mức gợi ý)'));
  });

  test('số trên màn khớp với số trong công thức của app', () {
    for (final level in ActivityLevel.values) {
      expect(allText, contains(formatDecimal(level.factor, maxFractionDigits: 3)), reason: level.name);
    }
    for (final group in ProteinGroup.values) {
      final min = formatDecimal(group.minGramsPerKg);
      final max = formatDecimal(group.maxGramsPerKg);
      expect(allText, contains(min == max ? '$min g/kg' : '$min–$max g/kg'), reason: group.name);
    }
    expect(allText, contains('${formatWhole(minimumIntakeKcal(BmrFormula.female))} kcal/ngày (nữ)'));
    expect(allText, contains('${formatWhole(minimumIntakeKcal(BmrFormula.male))} kcal/ngày (nam)'));
    expect(allText, contains('${formatDecimal(maxWeeklyChangeKg)} kg/tuần'));
    expect(allText, contains('${formatDecimal(referenceBmi)} × chiều cao (m)²'));
    expect(allText, contains('tối đa ${formatWhole(dailySodiumMaxMg)} mg/ngày'));
  });

  test('ngưỡng Fluw tự chọn đọc từ đúng hằng số mà các quy tắc dùng', () {
    expect(allText, contains('±${formatWhole(calorieToleranceShare * 100)}%'));
    expect(allText, contains('Dưới ${formatWhole(underLoggedShare * 100)}% mục tiêu calo'));
    expect(allText, contains('Có thể chưa ghi đủ món'));
    expect(allText, contains('Từ ${formatWhole(nearLimitShare * 100)}% mức gợi ý đường'));
    expect(allText, contains('Từ $eveningStartHour giờ, nếu còn từ ${formatWhole(eveningKcalLeft)} kcal'));
    expect(allText, contains('Món chiếm từ ${formatWhole(watchedPortionShare * 100)}%'));
  });

  test('không còn gì về tuổi 14–17: app chỉ dành cho người từ 18 tuổi', () {
    expect(allText, isNot(contains('14–17')));
    expect(allText, isNot(contains('14 tuổi')));
    expect(allText, isNot(contains('0.85')));
    expect(allText, isNot(contains('thiếu niên')));
  });

  testWidgets('mở từ nút ⓘ ở "Chỉ tiêu mỗi ngày", toàn màn hình, che thanh tab', (tester) async {
    await openProfileTab(tester);

    await scrollTo(tester, find.byTooltip('Cách Fluw tính'));
    await tester.tap(find.byTooltip('Cách Fluw tính'));
    await tester.pumpAndSettle();

    expect(find.byType(MethodologyScreen), findsOneWidget);
    expect(find.byType(FluwBottomBar).hitTestable(), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(MethodologyScreen), findsNothing);
  });

  testWidgets('mở từ thẻ "Về Fluw"', (tester) async {
    await openProfileTab(tester);
    await scrollTo(tester, find.text('Cách Fluw tính'));

    await tester.tap(find.text('Cách Fluw tính'));
    await tester.pumpAndSettle();

    expect(find.byType(MethodologyScreen), findsOneWidget);
    expect(find.text('Năng lượng cơ bản (BMR)'), findsOneWidget);
  });

  for (final textScale in [2.0, 3.1]) {
    testWidgets('320x568, cỡ chữ ${(textScale * 100).round()}%: màn Cách Fluw tính không tràn', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await loadAppFonts();
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const MethodologyScreen()));

      final lastTitle = methodologySections.last.items.last.title;
      await scrollTo(tester, find.text(lastTitle));
      expect(tester.takeException(), isNull);
    });
  }
}
