import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/clock_provider.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/note/data/note_providers.dart';
import 'package:fluw/features/note/presentation/note_screen.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/presentation/profile_screen.dart';
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
      isSemantics(value: '600 kcal, mục tiêu 2,083 kcal'),
    );
    expect(find.text('1,483 kcal'), findsOneWidget, reason: 'còn lại 2,083 - 600');
    expect(find.textContaining('30 g / cần ít nhất 112 g'), findsOneWidget);
    expect(
      find.textContaining('5 g / mức gợi ý 26 g'),
      findsOneWidget,
      reason: 'tiểu đường: đường tổng gợi ý dưới 5% năng lượng',
    );

    await scrollTo(tester, find.text('Phở bò'));
    expect(find.text('600 kcal'), findsOneWidget);
    expect(find.text('Chưa ghi món'), findsNWidgets(3));

    await scrollTo(tester, find.text('Đánh giá hôm qua'));
    expect(find.text('Năng lượng: thấp hơn mục tiêu 583 kcal'), findsOneWidget);
    expect(find.text('Protein (đạm): thiếu 92 g'), findsOneWidget);
    expect(find.text('Đường tổng: cao hơn mức gợi ý 4 g'), findsOneWidget);

    await scrollTo(tester, find.text('Bổ sung protein (đạm)'));
    expect(find.text('Hạn chế đồ ngọt'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('"Ghi món" ở một khung trống mở Tra Cứu và ghi nhớ đúng ngày và khung', (tester) async {
    await pumpFluwApp(tester);
    await withProfileAndMeals(tester);

    await scrollTo(tester, find.text('Trưa / Chiều (12:01 - 18:00)'));
    await tester.tap(find.widgetWithText(FilledButton, 'Ghi món').first);
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(
      appContainer(tester).read(diaryTargetProvider),
      DiaryTarget(day: CalendarDate(2026, 11, 11), slot: MealSlot.afternoon),
    );
  });

  testWidgets('"Ghi món" lúc 00:00:30: ngày Nhật ký lấy từ cùng đồng hồ với khung, vẫn là hôm trước', (tester) async {
    await pumpFluwApp(
      tester,
      overrides: [
        todayProvider.overrideWithValue(CalendarDate(2026, 11, 12)),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 12, 0, 0, 30)),
      ],
    );

    await scrollTo(tester, find.text('Sáng (06:00 - 12:00)'));
    await tester.tap(find.bySemanticsLabel('Ghi món vào buổi sáng'));
    await tester.pumpAndSettle();

    expect(
      appContainer(tester).read(diaryTargetProvider),
      DiaryTarget(day: CalendarDate(2026, 11, 11), slot: MealSlot.morning),
    );
  });

  testWidgets('người lớn không có huyết áp cao vẫn có thanh natri; carb gọi là "Carb (bột đường)"', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 11, 7, 30), kcal: 120));

    expect(find.text('Natri'), findsOneWidget);
    expect(find.textContaining('/ tối đa 2,000 mg'), findsOneWidget);
    expect(find.text('Carb (bột đường)'), findsOneWidget);
    expect(find.text('Tinh bột'), findsNothing);
  });

  testWidgets('vượt mục tiêu calo theo số hiện: 2,084 / 2,083 kcal là vượt 1 kcal, không bao giờ "vượt 0 kcal"', (
    tester,
  ) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    // 2,083.55 kcal eaten against a target of 2,083.06 kcal: shown as 2,084 and 2,083.
    await addEntry(tester, _entry('a', 'Tiệc', DateTime(2026, 11, 11, 7, 30), kcal: 416.71));

    expect(find.text('Đã vượt'), findsOneWidget);
    expect(find.text('1 kcal'), findsOneWidget);
  });

  testWidgets('hôm qua ghi chưa tới 50% mục tiêu calo: "Có thể chưa ghi đủ món", không kết luận ăn thiếu', (
    tester,
  ) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await addEntry(tester, _entry('a', 'Cơm tấm', DateTime(2026, 11, 10, 12, 30), kcal: 100));

    await scrollTo(tester, find.text('Đánh giá hôm qua'));
    expect(find.text('Năng lượng: có thể chưa ghi đủ món (mới ghi 500 kcal)'), findsOneWidget);
    expect(find.textContaining('Năng lượng: thấp hơn mục tiêu'), findsNothing);
    expect(find.text('Natri: chưa có dữ liệu'), findsOneWidget, reason: 'natri xét cho mọi người lớn');
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

  testWidgets('món thiếu calo: không tính "còn lại" như 0, nói rõ chưa có dữ liệu', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => appContainer(tester)
          .read(noteRepositoryProvider)
          .add(
            NoteEntry(
              id: 'tea',
              name: 'Trà',
              sourceFoodId: null,
              facts: NutritionFacts(per100: Nutrients(const {Nutrient.proteinG: 1}), unit: QuantityUnit.milliliter),
              quantity: 300,
              eatenAt: DateTime(2026, 11, 11, 8),
            ),
          ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có dữ liệu calo của các món hôm nay'), findsOneWidget);
    expect(find.text('Còn lại hôm nay'), findsNothing);
  });

  testWidgets('dưới 18 tuổi: không bảo đi sửa hồ sơ', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(
      () =>
          appContainer(tester)
              .read(profileRepositoryProvider)
              .save(buildProfile(birthDate: CalendarDate(2010, 1, 1), weeklyChangeKg: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fluw dành cho người từ 18 tuổi.'), findsOneWidget);
    expect(find.textContaining('hồ sơ người lớn'), findsNothing);
  });

  testWidgets('mang thai hoặc cho con bú: không có mục tiêu calo, không bảo đi sửa hồ sơ', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(
      () =>
          appContainer(tester)
              .read(profileRepositoryProvider)
              .save(buildProfile(sex: Sex.female, isPregnantOrBreastfeeding: true, weeklyChangeKg: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mang thai hoặc cho con bú: Fluw không tính calo.'), findsOneWidget);
    expect(find.text('Hồ sơ chưa đủ để tính mục tiêu calo.'), findsNothing);
  });

  testWidgets('hồ sơ không đọc được: nút mở tab Hồ Sơ, không mở form trống có thể ghi đè', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await tester.runAsync(() {
      final database = appContainer(tester).read(appDatabaseProvider);
      return database.update(database.profiles).write(const ProfilesCompanion(sex: Value('unknown')));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Mở Hồ Sơ'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(ProfileSetupScreen), findsNothing);
  });

  testWidgets('trình đọc màn hình: nút "Ghi món" nói rõ khung giờ', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpFluwApp(tester);
    await scrollTo(tester, find.text('Trưa / Chiều (12:01 - 18:00)'));

    expect(find.bySemanticsLabel('Ghi món vào buổi trưa / chiều'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('cỡ chữ 310%: nút "Ghi món" xuống dưới tên khung, tên khung không bị bóp hẹp', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await pumpFluwApp(tester);
    await scrollTo(tester, find.text('Trưa / Chiều (12:01 - 18:00)'));

    expect(tester.getRect(find.text('Trưa / Chiều (12:01 - 18:00)')).width, greaterThan(200));
    // The second slot in display order is Trưa / Chiều; every slot is empty here.
    final button = find.widgetWithText(FilledButton, 'Ghi món').at(1);
    await scrollTo(tester, button);
    // Measured after the last scroll, so both rects are in the same frame.
    final label = tester.getRect(find.text('Trưa / Chiều (12:01 - 18:00)'));
    expect(tester.getRect(button).top, greaterThanOrEqualTo(label.bottom));
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
