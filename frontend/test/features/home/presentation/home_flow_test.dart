import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/data/note_providers.dart';
import 'package:fluw/features/note/presentation/note_screen.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/presentation/profile_setup_screen.dart';
import 'package:fluw/features/scan/presentation/scan_screen.dart';
import 'package:fluw/features/search/presentation/search_screen.dart';

import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../profile/domain/profile_fixture.dart';

NoteEntry _entry(String id, String name, DateTime at, {required double kcal, double protein = 6, double sugar = 1}) {
  return NoteEntry(
    id: id,
    name: name,
    sourceFoodId: null,
    facts: NutritionFacts(
      per100: Nutrients({Nutrient.energyKcal: kcal, Nutrient.proteinG: protein, Nutrient.sugarsG: sugar}),
      unit: QuantityUnit.gram,
    ),
    quantity: 500,
    eatenAt: at,
  );
}

void main() {
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

  Future<void> addEntry(WidgetTester tester, NoteEntry entry) async {
    await tester.runAsync(() => appContainer(tester).read(noteRepositoryProvider).add(entry));
    await tester.pumpAndSettle();
  }

  Future<void> withProfileAndMeals(WidgetTester tester) async {
    await tester.runAsync(
      () =>
          appContainer(tester)
              .read(profileRepositoryProvider)
              .save(buildProfile(displayName: 'An', conditions: {HealthCondition.diabetes})),
    );
    await tester.pumpAndSettle();
    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 11, 7, 30), kcal: 120));
    await addEntry(tester, _entry('b', 'Cơm tấm', DateTime(2026, 11, 10, 12, 30), kcal: 300, protein: 4, sugar: 6));
  }

  testWidgets('chưa có hồ sơ: chào bạn, mời thiết lập hồ sơ và mở được màn thiết lập', (tester) async {
    await pumpFluwApp(tester);

    expect(find.text('Chào bạn'), findsOneWidget);
    expect(find.text('Chưa có mục tiêu calo'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Thiết lập hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });

  testWidgets('có hồ sơ và món: lời chào, vòng calo, bữa hôm nay, đánh giá hôm qua, gợi ý theo hồ sơ', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpFluwApp(tester);
    await withProfileAndMeals(tester);

    expect(find.text('Chào An'), findsOneWidget);
    expect(find.text('Mục tiêu: Giảm cân'), findsOneWidget);
    expect(find.text('Theo dõi: đường'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Năng lượng đã nạp hôm nay')),
      isSemantics(value: '600 trên 2,083 kcal'),
    );
    expect(find.text('1,483 kcal'), findsOneWidget, reason: 'còn lại 2,083 - 600');
    expect(find.textContaining('30 g / cần ít nhất 126 g'), findsOneWidget);
    expect(find.textContaining('5 g / tối đa 26 g'), findsOneWidget, reason: 'tiểu đường: đường dưới 5% năng lượng');

    await scrollTo(tester, find.text('Phở bò'));
    expect(find.text('600 kcal'), findsOneWidget);
    expect(find.text('Chưa ghi món'), findsNWidgets(3));

    await scrollTo(tester, find.text('Đánh giá hôm qua'));
    expect(find.text('Năng lượng: thấp hơn mục tiêu 583 kcal'), findsOneWidget);
    expect(find.text('Protein (đạm): thiếu 106 g'), findsOneWidget);
    expect(find.text('Đường tổng: vượt giới hạn 4 g'), findsOneWidget);

    await scrollTo(tester, find.text('Bổ sung protein (đạm)'));
    expect(find.text('Hạn chế đồ ngọt'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('"Ghi món" ở một khung trống mở Tra Cứu và ghi nhớ đúng ngày và khung', (tester) async {
    await pumpFluwApp(tester);
    await withProfileAndMeals(tester);

    await scrollTo(tester, find.text('Trưa / Chiều (12:01 - 18:00)'));
    await tester.tap(find.widgetWithText(TextButton, 'Ghi món').first);
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(
      appContainer(tester).read(diaryTargetProvider),
      DiaryTarget(day: CalendarDate(2026, 11, 11), slot: MealSlot.afternoon),
    );
  });

  testWidgets('lối tắt và "Xem Nhật ký" mở đúng tab', (tester) async {
    await pumpFluwApp(tester);

    await scrollTo(tester, find.text('Quét mã vạch'));
    await tester.tap(find.text('Quét mã vạch'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);

    await tester.tap(find.text(AppTab.home.label).last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Tra cứu thực phẩm'));
    await tester.tap(find.text('Tra cứu thực phẩm'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);

    await tester.tap(find.text(AppTab.home.label).last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Xem Nhật ký'));
    await tester.tap(find.text('Xem Nhật ký'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteScreen), findsOneWidget);
  });

  for (final textScale in [2.0, 3.1]) {
    testWidgets('320x568 cỡ chữ ${(textScale * 100).round()}%: Trang Chủ có hồ sơ và món không tràn', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await loadAppFonts();
      await pumpFluwApp(tester);
      await withProfileAndMeals(tester);

      expect(tester.takeException(), isNull);
      for (final text in ['Phở bò', 'Đánh giá hôm qua', 'Bổ sung protein (đạm)', 'Tra cứu thực phẩm']) {
        await scrollTo(tester, find.text(text));
        expect(tester.takeException(), isNull, reason: text);
      }
    });
  }
}
