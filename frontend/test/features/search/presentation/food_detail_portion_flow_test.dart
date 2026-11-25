import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../profile/domain/profile_fixture.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

/// Search answers [item]; the barcode lookup answers [product], or "not found" when it is null.
MockClient _backend(Map<String, Object?> item, {Map<String, Object?>? product}) => MockClient((request) async {
  if (request.url.path == '/api/foods/search') {
    return _json(searchBody(request.url.queryParameters['q']!, [item]));
  }
  if (product == null) {
    return _json({
      'error': {'code': 'PRODUCT_NOT_FOUND', 'message': 'Không tìm thấy sản phẩm.'},
    }, 404);
  }
  return _json({'item': product});
});

void main() {
  void tallView(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(390, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// In [tallView], so the whole detail page is built, unless [keepView] (the test set its own size).
  Future<void> openDetail(
    WidgetTester tester,
    MockClient backend,
    String name, {
    bool withProfile = false,
    bool keepView = false,
  }) async {
    if (!keepView) {
      tallView(tester);
    }
    await pumpFluwApp(tester, httpClient: backend);
    if (withProfile) {
      await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'tìm thử');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    final list = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical);
    await tester.scrollUntilVisible(find.text(name), 200, scrollable: list.hitTestable().first);
    await tester.ensureVisible(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  Finder portionField() => find.widgetWithText(TextField, 'Khẩu phần bạn ăn');
  String portionText(WidgetTester tester) => tester.widget<TextField>(portionField()).controller!.text;
  bool chipSelected(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;

  testWidgets(
    'latte không ghi dung tích: thẻ ghi "Trong 100 g"; Chi tiết hỏi dung tích, năng lượng nói rõ cho bao nhiêu g, đối '
    'chiếu nằm dưới ô khẩu phần và nói khẩu phần; nút thêm và thông báo nói lượng và kcal',
    (tester) async {
      tallView(tester);
      await pumpFluwApp(tester, httpClient: _backend(latteItem, product: latteProduct));
      await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppTab.search.label).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'latte trà sữa');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Trong 100 g'), findsOneWidget, reason: '26 kcal không được trông như cả chai');
      expect(find.text('26 kcal'), findsOneWidget);

      await tester.tap(find.text('Latte trà sữa'));
      await tester.pumpAndSettle();

      expect(portionText(tester), '100');
      expect(find.text('26 kcal cho 100 g'), findsOneWidget);
      final hint = find.text(packSizeMissingHint(QuantityUnit.gram));
      expect(hint, findsOneWidget);
      expect(tester.getTopLeft(hint).dy, lessThan(tester.getTopLeft(portionField()).dy));

      await tester.enterText(portionField(), '440');
      await tester.pumpAndSettle();

      expect(find.text('114 kcal cho 440 g'), findsOneWidget);
      expect(find.text('440 g này chiếm trong chỉ tiêu cả ngày:'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Đối chiếu hồ sơ của bạn')).dy,
        greaterThan(tester.getTopLeft(portionField()).dy),
      );
      expect(find.text('Bảng dinh dưỡng trong 100 g'), findsOneWidget);
      expect(find.text('440 g · 114 kcal'), findsOneWidget, reason: 'nút thêm nói lượng và kcal');

      await tester.tap(find.widgetWithText(FilledButton, 'Thêm vào Nhật ký'));
      await tester.pumpAndSettle();
      expect(find.text('Đã thêm Latte trà sữa (440 g · 114 kcal) vào buổi Sáng hôm nay'), findsOneWidget);
    },
  );

  testWidgets('máy chủ gửi dung tích cả chai: chip "Cả chai (440 ml)" chọn sẵn, không hỏi dung tích', (tester) async {
    final bottle = {
      ...colaItem,
      'servingSize': null,
      'packageQuantity': {'amount': 440, 'unit': 'ml'},
    };
    await openDetail(tester, _backend(bottle, product: bottle), 'Coca-Cola');

    expect(portionText(tester), '440');
    expect(chipSelected(tester, 'Cả chai (440 ml)'), isTrue);
    expect(find.text(packSizeMissingHint(QuantityUnit.milliliter)), findsNothing);
  });

  testWidgets('khẩu phần dạng số thắng chuỗi servingSize; cả gói theo g có chip "Cả gói"', (tester) async {
    final pack = {
      ...yoghurtSearchItem,
      'servingSize': '1 hũ (120 g)',
      'servingQuantity': {'amount': 100, 'unit': 'g'},
      'packageQuantity': {'amount': 400, 'unit': 'g'},
    };
    await openDetail(tester, _backend(pack, product: pack), 'Vinamilk sữa chua dâu');

    expect(portionText(tester), '100');
    expect(chipSelected(tester, '1 khẩu phần (100 g)'), isTrue);
    expect(find.widgetWithText(ChoiceChip, 'Cả gói (400 g)'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '1 khẩu phần (120 g)'), findsNothing);
  });

  testWidgets('dung tích khác đơn vị của số liệu (ml cho số liệu theo g) thì không thành chip, vẫn hỏi', (
    tester,
  ) async {
    final latte = {
      ...latteProduct,
      'packageQuantity': {'amount': 440, 'unit': 'ml'},
    };
    await openDetail(tester, _backend(latte, product: latte), 'Latte trà sữa');

    expect(portionText(tester), '100');
    expect(find.widgetWithText(ChoiceChip, 'Cả chai (440 ml)'), findsNothing);
    expect(find.text(packSizeMissingHint(QuantityUnit.gram)), findsOneWidget);
  });

  testWidgets('máy chủ cũ không gửi các trường mới: vẫn như trước (100 g, hỏi dung tích, không cảnh báo)', (
    tester,
  ) async {
    await openDetail(tester, _backend(latteItem, product: latteProduct), 'Latte trà sữa');

    expect(portionText(tester), '100');
    expect(find.text(suspectNutrientsNote), findsNothing);
    expect(find.text(productGoneNote), findsNothing);
  });

  testWidgets('số liệu nguồn có thể sai: thẻ ghi chú, lọc nhanh loại ra và nói rõ, Chi tiết bảo đối chiếu nhãn', (
    tester,
  ) async {
    final suspect = {
      ...yoghurtSearchItem,
      'name': 'Bánh số liệu lạ',
      'nutrients': {'energyKcal': 120, 'proteinG': 81, 'sugarsG': 2},
      'nutrientsSuspect': true,
    };
    await pumpFluwApp(tester, httpClient: _backend(suspect, product: suspect));
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'bánh');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Số liệu nguồn có thể sai'), findsOneWidget);
    await tester.tap(find.text('Dưới 200 kcal'));
    await tester.pumpAndSettle();
    expect(find.text('Bánh số liệu lạ'), findsNothing, reason: '120 kcal nhưng số liệu không đáng tin');
    expect(find.textContaining('1 món có số liệu nguồn có thể sai.'), findsOneWidget);

    await tester.tap(find.text('Đặt lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bánh số liệu lạ'));
    await tester.pumpAndSettle();
    expect(find.text(suspectNutrientsNote), findsOneWidget);
  });

  testWidgets('sản phẩm không còn trên Open Food Facts: nói số liệu có thể đã cũ, không im lặng hiện số cũ', (
    tester,
  ) async {
    await openDetail(tester, _backend(yoghurtSearchItem), 'Vinamilk sữa chua dâu');

    expect(find.text(productGoneNote), findsOneWidget);
    expect(find.textContaining('Chưa tải được đủ thông tin sản phẩm'), findsNothing);
    expect(find.text('99 kcal cho 100 g'), findsOneWidget, reason: 'số từ kết quả tìm kiếm vẫn hiện, kèm lời báo');
  });

  testWidgets('khẩu phần trên bao bì không có số thì không hiện; có số nhưng khác đơn vị thì nói rõ', (tester) async {
    final wordOnly = {...latteProduct, 'servingSize': 'serving'};
    await openDetail(tester, _backend(wordOnly, product: wordOnly), 'Latte trà sữa');
    expect(find.textContaining('Khẩu phần ghi trên bao bì'), findsNothing);
    expect(find.text(packSizeMissingHint(QuantityUnit.gram)), findsOneWidget);
  });

  testWidgets('khẩu phần trên bao bì theo ml cho số liệu theo g: hiện chữ trên bao bì và nhắc nhập số g', (
    tester,
  ) async {
    final cola = {...latteProduct, 'servingSize': '1 portion (330 ml)'};
    await openDetail(tester, _backend(cola, product: cola), 'Latte trà sữa');
    expect(find.text('Khẩu phần ghi trên bao bì: 1 portion (330 ml)'), findsOneWidget);
    expect(find.text(servingNotInUnitHint(QuantityUnit.gram)), findsOneWidget);
  });

  testWidgets('tên USDA (sống hay chín) hiện đủ ở thẻ kết quả và ở Chi tiết, không bị cắt', (tester) async {
    const name = 'Chicken, broiler, breast, meat only, cooked, roasted';
    await pumpFluwApp(tester, httpClient: _backend(chickenItem));
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ức gà');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final onCard = tester.widget<Text>(find.text(name));
    expect((onCard.maxLines, onCard.overflow), (null, null));
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    final onDetail = tester.widget<Text>(find.text(name));
    expect((onDetail.maxLines, onDetail.overflow), (null, null));
  });

  for (final textScale in [2.0, 3.1]) {
    testWidgets('320x568, cỡ chữ ${(textScale * 100).round()}%: Chi tiết món không ghi dung tích không tràn', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await loadAppFonts();
      final suspect = {
        ...latteProduct,
        'nutrientsSuspect': true,
        'packageQuantity': {'amount': 440, 'unit': 'g'},
      };
      await openDetail(tester, _backend(suspect, product: suspect), 'Latte trà sữa', withProfile: true, keepView: true);
      expect(tester.takeException(), isNull);
      expect(find.text('Chi tiết dinh dưỡng'), findsOneWidget);

      final list = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical);
      final element = list.hitTestable().evaluate().first;
      await tester.scrollUntilVisible(
        find.textContaining('Nguồn: Open Food Facts'),
        300,
        scrollable: find.byElementPredicate((e) => identical(e, element)),
        maxScrolls: 300,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
