import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/note/data/note_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';

final NutritionFacts _phoFacts = NutritionFacts(
  per100: Nutrients({Nutrient.energyKcal: 110, Nutrient.proteinG: 6}),
  unit: QuantityUnit.gram,
);

NoteEntry _entry(String id, String name, DateTime eatenAt, {String? source, double quantity = 300}) =>
    NoteEntry(id: id, name: name, sourceFoodId: source, facts: _phoFacts, quantity: quantity, eatenAt: eatenAt);

void main() {
  final backend = MockClient(
    (request) async => http.Response.bytes(utf8.encode(jsonEncode(searchBody('gà', [chickenItem]))), 200),
  );

  Future<void> addEntry(WidgetTester tester, NoteEntry entry) async {
    await tester.runAsync(() => appContainer(tester).read(noteRepositoryProvider).add(entry));
    await tester.pumpAndSettle();
  }

  Future<List<NoteEntry>> storedOn(WidgetTester tester, DateTime from, DateTime to) async {
    final window = await tester.runAsync(
      () => appContainer(tester).read(noteRepositoryProvider).watchBetween(from, to).first,
    );
    return window!.entries;
  }

  Future<void> openSearch(WidgetTester tester) async {
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('chưa tìm gì thì gợi ý món đã ăn gần đây (mỗi món một lần, mới nhất trước); Nhật ký trống thì không', (
    tester,
  ) async {
    await pumpFluwApp(tester, httpClient: backend);
    await openSearch(tester);
    expect(find.text('Món đã ăn gần đây'), findsNothing);

    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 9, 7), source: 'off:1', quantity: 250));
    await addEntry(tester, _entry('b', 'Cơm nhà', DateTime(2026, 11, 10, 12), quantity: 100));
    await addEntry(tester, _entry('c', 'Phở bò', DateTime(2026, 11, 11, 7), source: 'off:1'));

    expect(find.text('Món đã ăn gần đây'), findsOneWidget);
    expect(find.text('Phở bò'), findsOneWidget);
    expect(find.text('Lần trước 300 g · 330 kcal'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Phở bò')).dy, lessThan(tester.getTopLeft(find.text('Cơm nhà')).dy));
  });

  testWidgets('chạm món gần đây: ghi lại bằng số liệu đã lưu, không cần mạng, khẩu phần đổi được', (tester) async {
    await pumpFluwApp(tester);
    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 10, 7), source: 'off:1'));
    await openSearch(tester);

    await tester.tap(find.text('Phở bò'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dùng số liệu đã lưu lần trước. Khẩu phần này: 330 kcal.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'), '200');
    await tester.pumpAndSettle();
    expect(find.textContaining('Khẩu phần này: 220 kcal.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing, reason: 'thêm xong thì đóng');
    expect(find.text('Đã thêm Phở bò vào buổi Sáng hôm nay'), findsOneWidget);
    final today = await storedOn(tester, DateTime(2026, 11, 11), DateTime(2026, 11, 12));
    expect(today.single.name, 'Phở bò');
    expect(today.single.sourceFoodId, 'off:1');
    expect(today.single.facts, _phoFacts);
    expect(today.single.quantity, 200);
  });

  testWidgets('đã tìm thì ẩn món gần đây; nút Xóa từ khóa đưa về màn trống có món gần đây', (tester) async {
    await pumpFluwApp(tester, httpClient: backend);
    await addEntry(tester, _entry('a', 'Phở bò', DateTime(2026, 11, 10, 7), source: 'off:1'));
    await openSearch(tester);

    await tester.enterText(find.byType(TextField).first, 'gà');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Món đã ăn gần đây'), findsNothing);
    expect(find.text('1 kết quả cho "gà"'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa từ khóa'));
    await tester.pumpAndSettle();

    expect(find.text('Món đã ăn gần đây'), findsOneWidget);
    expect(find.text('1 kết quả cho "gà"'), findsNothing);
    expect(find.byTooltip('Xóa từ khóa'), findsNothing);
  });

  testWidgets('320x568 cỡ chữ 310%: món gần đây và bảng ghi lại không tràn, thấy nút thêm', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await pumpFluwApp(tester);
    await addEntry(tester, _entry('a', 'Bún bò Huế đặc biệt nhiều thịt', DateTime(2026, 11, 10, 7), source: 'off:1'));
    await openSearch(tester);

    final list = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical).hitTestable();
    final element = list.evaluate().first;
    await tester.scrollUntilVisible(
      find.text('Bún bò Huế đặc biệt nhiều thịt'),
      200,
      scrollable: find.byElementPredicate((e) => identical(e, element)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Bún bò Huế đặc biệt nhiều thịt'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký').hitTestable(), findsOneWidget);
  });
}
