import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/diary/food_logger.dart';
import 'package:fluw/core/diary/logged_food.dart';
import 'package:fluw/core/diary/meal_slot.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/data/note_providers.dart';
import 'package:fluw/features/note/domain/note_entry.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/search/presentation/add_to_note_bar.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../profile/domain/profile_fixture.dart';

final class _FailingLogger implements FoodLogger {
  @override
  Future<void> log(LoggedFood food) => Future.error(StateError('ổ đĩa đầy'));
}

NoteEntry _entry(String id, String name, DateTime eatenAt, {double? kcalPer100 = 200, double quantity = 100}) {
  return NoteEntry(
    id: id,
    name: name,
    sourceFoodId: null,
    facts: NutritionFacts(
      per100: Nutrients({Nutrient.energyKcal: ?kcalPer100, Nutrient.proteinG: 10, Nutrient.sugarsG: 5}),
      unit: QuantityUnit.gram,
    ),
    quantity: quantity,
    eatenAt: eatenAt,
  );
}

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder, {double delta = 200}) async {
    final list = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical).hitTestable();
    final element = list.evaluate().first;
    await tester.scrollUntilVisible(
      finder,
      delta,
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

  Future<void> openNote(WidgetTester tester) async {
    await tester.tap(find.text(AppTab.note.label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Nhật ký trống: đủ 4 khung theo thứ tự thiết kế, có giờ, chưa ăn gì là 0', (tester) async {
    // Tall enough to lay out all four slots at once, so their order can be compared.
    tester.view
      ..physicalSize = const Size(390, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpFluwApp(tester);
    await openNote(tester);

    expect(find.text('Tháng 11, 2026'), findsOneWidget);
    expect(find.text('0 kcal'), findsOneWidget, reason: 'chưa ăn gì là 0 thật, không phải thiếu dữ liệu');
    expect(find.text('Thiết lập hồ sơ để so với chỉ tiêu mỗi ngày.'), findsOneWidget);
    final tops = [
      for (final title in ['Sáng', 'Trưa / Chiều', 'Tối', 'Khuya / Đêm']) tester.getTopLeft(find.text(title)).dy,
    ];
    expect([...tops]..sort(), tops, reason: 'thứ tự hiển thị Sáng, Trưa / Chiều, Tối, Khuya / Đêm');
    await scrollTo(tester, find.text('00:01 - 05:59'));
    expect(find.text('00:01 - 05:59'), findsOneWidget);
  });

  testWidgets('món đã ghi hiện đúng ngày và khung; tổng ngày so với mục tiêu của hồ sơ', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 11, 7, 30), quantity: 300));
    await addEntry(tester, _entry('b', 'Mì gói', DateTime(2026, 11, 12)));
    await addEntry(tester, _entry('c', 'Bánh mì', DateTime(2026, 11, 10, 8)));
    await openNote(tester);

    expect(find.text('Phở bò'), findsOneWidget);
    expect(find.text('Bánh mì'), findsNothing, reason: 'món ngày 10 không hiện ở ngày 11');
    expect(find.textContaining('800 kcal / mục tiêu'), findsOneWidget, reason: '600 + 200 lúc 00:00 ngày 12');
    await scrollTo(tester, find.text('Mì gói'));
    expect(find.textContaining('00:00 · 100 g'), findsOneWidget);

    await scrollTo(tester, find.text('Tháng 11, 2026'), delta: -200);
    await tester.tap(find.bySemanticsLabel(RegExp('ngày 10 tháng 11, có món đã ghi')));
    await tester.pumpAndSettle();

    expect(find.text('Về hôm nay'), findsOneWidget);
    await scrollTo(tester, find.text('Bánh mì'));
    expect(find.text('Phở bò'), findsNothing);
  });

  testWidgets('xóa món rồi bấm Hoàn tác thì món quay lại', (tester) async {
    await pumpFluwApp(tester);
    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 11, 7, 30)));
    await openNote(tester);

    await scrollTo(tester, find.byTooltip('Xóa Phở bò'));
    await tester.tap(find.byTooltip('Xóa Phở bò'));
    await tester.pumpAndSettle();
    expect(find.text('Phở bò'), findsNothing);
    expect(find.text('Đã xóa Phở bò'), findsOneWidget);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(find.text('Phở bò'), findsOneWidget);
  });

  testWidgets('món thiếu calo: tổng ghi rõ có món thiếu số liệu, không coi là 0', (tester) async {
    await pumpFluwApp(tester);
    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 11, 7, 30)));
    await addEntry(tester, _entry('b', 'Trà', DateTime(2026, 11, 11, 13), kcalPer100: null));
    await openNote(tester);

    expect(find.text('Có món thiếu số liệu nên tổng có thể thấp hơn thực tế.'), findsOneWidget);
    await scrollTo(tester, find.text('Năng lượng chưa có dữ liệu'));
    expect(find.text('Năng lượng chưa có dữ liệu'), findsOneWidget);
    expect(find.textContaining('Năng lượng chưa có · Protein (đạm) 10 g'), findsOneWidget);
  });

  final chickenBackend = MockClient(
    (request) async => http.Response.bytes(utf8.encode(jsonEncode(searchBody('gà', [chickenItem]))), 200),
  );

  Future<void> openChickenDetail(WidgetTester tester, {bool fromSearchTab = true}) async {
    if (fromSearchTab) {
      await tester.tap(find.text(AppTab.search.label).last);
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField).first, 'gà');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(chickenItem['name']! as String));
    await tester.tap(find.text(chickenItem['name']! as String));
    await tester.pumpAndSettle();
  }

  Finder inAddBar(Finder finder) => find.descendant(of: find.byType(AddToNoteBar), matching: finder);

  Future<List<NoteEntry>> storedOn(WidgetTester tester, DateTime from, DateTime to) async {
    final window = await tester.runAsync(
      () => appContainer(tester).read(noteRepositoryProvider).watchBetween(from, to).first,
    );
    return window!.entries;
  }

  testWidgets('thêm món từ Chi tiết vào khung đã chọn của ngày nhật ký hiện tại; khẩu phần sai thì tắt nút', (
    tester,
  ) async {
    await pumpFluwApp(tester, httpClient: chickenBackend);
    await openChickenDetail(tester);
    final current = DiaryTarget.current(DateTime.now()).day;

    expect(find.text('Thêm vào Nhật ký hôm nay'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'), '0');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký')).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'), '200');
    await tester.pumpAndSettle();
    await tester.tap(find.text('18–24h'));
    await tester.pumpAndSettle();
    expect(inAddBar(find.text('Tối')), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký'));
    await tester.pumpAndSettle();

    expect(find.textContaining('vào buổi Tối hôm nay'), findsOneWidget);
    final stored = await storedOn(
      tester,
      DateTime(current.year, current.month, current.day),
      DateTime(current.year, current.month, current.day + 2),
    );
    expect(stored.single.quantity, 200);
    expect(stored.single.sourceFoodId, 'usda:171477');
    expect(stored.single.placement, (day: current, slot: MealSlot.evening));
  });

  testWidgets('"Thêm món" ở một khung của ngày đang xem: món vào đúng ngày và khung đó, rồi hiện trong Nhật ký', (
    tester,
  ) async {
    await pumpFluwApp(tester, httpClient: chickenBackend);
    await openNote(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('ngày 10 tháng 11')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Thêm món vào buổi sáng'));
    await tester.tap(find.text('Thêm món vào buổi sáng'));
    await tester.pumpAndSettle();
    await openChickenDetail(tester, fromSearchTab: false);

    expect(find.text('Thêm vào Nhật ký ngày 10/11'), findsOneWidget);
    expect(inAddBar(find.text('Sáng')), findsOneWidget, reason: 'khung đang chọn hiện tên đầy đủ');
    await tester.enterText(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'), '200');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký'));
    await tester.pumpAndSettle();

    expect(find.textContaining('vào buổi Sáng ngày 10/11'), findsOneWidget);
    final stored = await storedOn(tester, DateTime(2026, 11, 10), DateTime(2026, 11, 11));
    expect(stored.single.placement, (day: CalendarDate(2026, 11, 10), slot: MealSlot.morning));
    expect(appContainer(tester).read(diaryTargetProvider), isNull, reason: 'thêm xong thì bỏ ngày đã chọn');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await openNote(tester);
    await scrollTo(tester, find.text('330 kcal'));
    expect(find.text('330 kcal'), findsOneWidget);
  });

  testWidgets('ghi vào Nhật ký lỗi thì báo, không im lặng', (tester) async {
    await pumpFluwApp(
      tester,
      httpClient: chickenBackend,
      overrides: [foodLoggerProvider.overrideWithValue(_FailingLogger())],
    );
    await openChickenDetail(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký'));
    await tester.pumpAndSettle();

    expect(find.text('Không thêm được vào Nhật ký. Vui lòng thử lại.'), findsOneWidget);
  });

  testWidgets('tuần có món lúc 00:01 thứ Hai (Đêm thứ Hai) và 00:00 thứ Hai sau (Tối Chủ nhật)', (tester) async {
    await pumpFluwApp(tester);
    await addEntry(tester, _entry('a', 'Cháo khuya', DateTime(2026, 11, 9, 0, 1)));
    await addEntry(tester, _entry('b', 'Mì nửa đêm', DateTime(2026, 11, 16, 0, 0, 59)));
    await addEntry(tester, _entry('c', 'Sữa thứ Hai sau', DateTime(2026, 11, 16, 0, 1)));
    await openNote(tester);

    await tester.tap(find.bySemanticsLabel(RegExp('ngày 9 tháng 11, có món đã ghi')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Cháo khuya'));
    expect(find.text('Cháo khuya'), findsOneWidget);

    await scrollTo(tester, find.text('Tháng 11, 2026'), delta: -200);
    await tester.tap(find.bySemanticsLabel(RegExp('ngày 15 tháng 11, có món đã ghi')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Mì nửa đêm'));
    expect(find.text('Mì nửa đêm'), findsOneWidget);
    expect(find.text('Sữa thứ Hai sau'), findsNothing);
  });

  testWidgets('người lớn có huyết áp cao: tổng ngày có protein tối thiểu, đường tối đa, natri, báo vượt', (
    tester,
  ) async {
    await pumpFluwApp(tester);
    await tester.runAsync(
      () =>
          appContainer(tester)
              .read(profileRepositoryProvider)
              .save(buildProfile(conditions: {HealthCondition.hypertension})),
    );
    await addEntry(tester, _entry('a', 'Tiệc', DateTime(2026, 11, 11, 7, 30), quantity: 2000));
    await openNote(tester);

    expect(find.textContaining('/ cần ít nhất'), findsOneWidget);
    expect(find.textContaining('/ tối đa'), findsNWidgets(2));
    expect(find.text('Natri'), findsOneWidget);
    expect(find.text('Béo bão hòa'), findsNothing, reason: 'không có mỡ máu cao');
    expect(find.text('Vượt mục tiêu calo cả ngày.'), findsOneWidget);
    expect(find.text('Vượt giới hạn cả ngày.'), findsOneWidget, reason: 'đường 100 g; natri chưa có dữ liệu');
  });

  testWidgets('hồ sơ không đọc được thì nói rõ chưa so được với chỉ tiêu', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await tester.runAsync(() {
      final database = appContainer(tester).read(appDatabaseProvider);
      return database.update(database.profiles).write(const ProfilesCompanion(sex: Value('unknown')));
    });
    await tester.pumpAndSettle();
    await openNote(tester);

    expect(find.text('Không đọc được hồ sơ nên chưa so được với chỉ tiêu.'), findsOneWidget);
  });

  testWidgets('dòng Nhật ký hỏng thì báo số món không đọc được', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() {
      final database = appContainer(tester).read(appDatabaseProvider);
      return database
          .into(database.noteEntries)
          .insert(
            NoteEntriesCompanion.insert(
              id: 'bad',
              name: 'Hỏng',
              unit: 'oz',
              quantity: 100,
              eatenAtUtcMs: DateTime(2026, 11, 11, 8).millisecondsSinceEpoch,
            ),
          );
    });
    await tester.pumpAndSettle();
    await openNote(tester);

    expect(find.text('Có 1 món trong tuần này không đọc được nên không tính vào tổng.'), findsOneWidget);
  });

  testWidgets('xóa liền hai món: hoàn tác được cả hai', (tester) async {
    await pumpFluwApp(tester);
    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 11, 7, 30)));
    await addEntry(tester, _entry('b', 'Bánh mì', DateTime(2026, 11, 11, 8)));
    await openNote(tester);

    for (final name in ['Phở bò', 'Bánh mì']) {
      await scrollTo(tester, find.byTooltip('Xóa $name'));
      await tester.tap(find.byTooltip('Xóa $name'));
      await tester.pumpAndSettle();
    }
    for (var count = 0; count < 2; count++) {
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
    }

    final stored = await storedOn(tester, DateTime(2026, 11, 11), DateTime(2026, 11, 12));
    expect(stored.map((entry) => entry.name), ['Phở bò', 'Bánh mì']);
  });

  testWidgets('320x568 cỡ chữ 310%: thanh thêm món ở Chi tiết thấy nút khi bàn phím đóng, không tràn', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await pumpFluwApp(tester, httpClient: chickenBackend);
    await openChickenDetail(tester);

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký').hitTestable(), findsOneWidget);
    await tester.tap(find.text('00–06h'));
    await tester.pumpAndSettle();
    expect(inAddBar(find.text('Khuya / Đêm')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bàn phím số (iPhone không có nút Xong) che thanh thêm món: chạm ra ngoài thì ẩn bàn phím', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpFluwApp(tester, httpClient: chickenBackend);
    await openChickenDetail(tester);

    await tester.tap(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    // The keyboard is not a widget in tests: check that the bar lies inside the area it covers.
    expect(tester.getRect(find.byType(AddToNoteBar)).top, greaterThanOrEqualTo(844 - 300));

    await tester.tapAt(tester.getCenter(find.text('Chi tiết dinh dưỡng')));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký').hitTestable(), findsOneWidget);
  });

  testWidgets('ô khung giờ: là nút, báo đang chọn cho trình đọc màn hình, cao ít nhất 48 dp', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpFluwApp(tester, httpClient: chickenBackend);
    await openChickenDetail(tester);
    await tester.tap(find.text('06–12h'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('Sáng, 06:00 - 12:00')),
      isSemantics(isButton: true, hasTapAction: true, hasSelectedState: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Tối, 18:01 - 24:00')),
      isSemantics(isButton: true, hasTapAction: true, hasSelectedState: true, isSelected: false),
    );
    expect(
      tester.getSize(find.ancestor(of: find.text('18–24h'), matching: find.byType(InkWell))).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  for (final textScale in [2.0, 3.1]) {
    testWidgets('320x568 cỡ chữ ${(textScale * 100).round()}%: Nhật ký có món không tràn', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await loadAppFonts();
      await pumpFluwApp(tester);
      await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
      await addEntry(tester, _entry('a', 'Bún bò Huế đặc biệt nhiều thịt', DateTime(2026, 11, 11, 7, 30)));
      await openNote(tester);

      expect(tester.takeException(), isNull);
      await scrollTo(tester, find.text('Bún bò Huế đặc biệt nhiều thịt'));
      expect(tester.takeException(), isNull);
      await scrollTo(tester, find.text('Khuya / Đêm'));
      expect(tester.takeException(), isNull);
    });
  }
}
