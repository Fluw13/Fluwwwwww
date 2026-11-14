import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/note/data/note_providers.dart';
import 'package:fluw/features/note/domain/note_entry.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../profile/domain/profile_fixture.dart';

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
    await addEntry(tester, _entry('b', 'Trà', DateTime(2026, 11, 11, 8), kcalPer100: null));
    await openNote(tester);

    expect(find.text('Có món thiếu số liệu nên tổng có thể thấp hơn thực tế.'), findsOneWidget);
    expect(find.text('Năng lượng chưa có dữ liệu'), findsOneWidget);
  });

  testWidgets('thêm món từ Chi tiết vào khung đã chọn, rồi thấy ngay trong Nhật ký', (tester) async {
    final backend = MockClient(
      (request) async => http.Response.bytes(utf8.encode(jsonEncode(searchBody('gà', [chickenItem]))), 200),
    );
    await pumpFluwApp(tester, httpClient: backend);
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'gà');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text(chickenItem['name']! as String));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Thêm vào Nhật ký'));
    await tester.enterText(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'), '0');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký')).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'), '200');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký'));
    await tester.pumpAndSettle();

    expect(find.textContaining('vào buổi Tối hôm nay'), findsOneWidget);
    final stored = await tester.runAsync(
      () =>
          appContainer(tester)
              .read(noteRepositoryProvider)
              .watchBetween(DateTime(2026, 11, 11), DateTime(2026, 11, 12))
              .first,
    );
    expect(stored!.single.quantity, 200);
    expect(stored.single.sourceFoodId, 'usda:171477');
    expect(stored.single.placement.slot.name, 'evening');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await openNote(tester);
    await scrollTo(tester, find.text('330 kcal'));
    expect(find.text('330 kcal'), findsOneWidget);
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
