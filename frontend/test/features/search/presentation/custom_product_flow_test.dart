import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/data/custom_product_repository.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:fluw/features/search/domain/custom_product.dart';
import 'package:fluw/features/search/presentation/custom_product_form_screen.dart';
import 'package:fluw/features/search/presentation/food_detail_screen.dart';
import 'package:fluw/features/search/presentation/food_result_card.dart';
import 'package:fluw/features/search/presentation/search_controller.dart';
import 'package:fluw/features/search/presentation/search_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../../helpers/scroll_to.dart';

const String _code = '8935001282266';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

/// Open Food Facts has no product; a search finds nothing there either.
MockClient _emptyBackend(List<Uri> calls) => MockClient((request) async {
  calls.add(request.url);
  if (request.url.path.startsWith('/api/foods/barcode/')) {
    return _json({
      'error': {'code': 'PRODUCT_NOT_FOUND', 'message': 'Không tìm thấy sản phẩm.'},
    }, 404);
  }
  return _json(searchBody(request.url.queryParameters['q']!, const []));
});

CustomProduct _latte({String id = 'latte', double kcal = 26}) => CustomProduct(
  id: id,
  name: 'Trà sữa latte',
  brand: null,
  barcode: _code,
  facts: NutritionFacts(
    per100: Nutrients({Nutrient.energyKcal: kcal, Nutrient.proteinG: 0.8}),
    unit: QuantityUnit.milliliter,
  ),
  packageAmount: 440,
  servingAmount: null,
  labelPerServing: false,
);

Finder _field(String label) => find.widgetWithText(TextField, label);

Future<void> _enter(WidgetTester tester, String label, String text) async {
  await scrollTo(tester, _field(label));
  await tester.enterText(_field(label), text);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The save runs on the real database; a short real-time wait lets its transaction finish.
Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Lưu sản phẩm'));
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pumpAndSettle();
}

String? _errorOf(WidgetTester tester, String label) => tester.widget<TextField>(_field(label)).decoration!.errorText;

Future<void> _saveStored(WidgetTester tester, CustomProduct product) =>
    tester.runAsync(() => appContainer(tester).read(customProductRepositoryProvider).save(product));

Future<CustomProduct?> _stored(WidgetTester tester, String id) =>
    tester.runAsync<CustomProduct?>(() => appContainer(tester).read(customProductRepositoryProvider).findById(id));

void main() {
  Future<void> scan(WidgetTester tester, String code) async {
    await tester.tap(find.text(AppTab.scan.label).last);
    await tester.pumpAndSettle();
    appBarcodeCamera(tester).scan(code);
    await tester.pumpAndSettle();
  }

  testWidgets('quét mã chưa có: nhập từ nhãn theo khẩu phần, lưu xong mở Chi tiết; lần quét sau không cần mạng', (
    tester,
  ) async {
    final calls = <Uri>[];
    await pumpFluwApp(tester, httpClient: _emptyBackend(calls));
    await scan(tester, _code);
    expect(find.text('Chưa có sản phẩm này'), findsOneWidget);

    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Nhập từ nhãn'));
    expect(find.byType(CustomProductFormScreen), findsOneWidget);
    expect(tester.widget<TextField>(_field('Mã vạch (không bắt buộc)')).controller!.text, _code);

    await _enter(tester, 'Tên sản phẩm', 'Trà sữa latte');
    await _tapVisible(tester, find.text('Thể tích (ml)'));
    await _tapVisible(tester, find.text('1 khẩu phần'));
    await _enter(tester, '1 khẩu phần (ml)', '440');
    await _enter(tester, 'Cả gói/chai (ml, không bắt buộc)', '440');
    await _enter(tester, 'Năng lượng (kcal)', '114');
    await _save(tester);

    expect(find.byType(CustomProductFormScreen), findsNothing);
    expect(find.byType(FoodDetailScreen), findsOneWidget);
    expect(find.text('Trà sữa latte'), findsOneWidget);
    expect(find.text('Bạn tự nhập'), findsOneWidget);
    expect(find.text('114 kcal cho 440 ml'), findsOneWidget, reason: 'mặc định 1 khẩu phần, không phải 100 ml');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    final callsBefore = calls.length;
    await scan(tester, _code);

    expect(find.byType(FoodDetailScreen), findsOneWidget);
    expect(find.text('Trà sữa latte'), findsOneWidget);
    expect(calls, hasLength(callsBefore), reason: 'sản phẩm tự nhập trả lời ngay trên máy');
  });

  testWidgets('lưu khi thiếu tên và năng lượng: báo đúng ô, không lưu', (tester) async {
    await pumpFluwApp(tester, httpClient: _emptyBackend([]));
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Nhập sản phẩm từ nhãn'));

    await _save(tester);

    expect(find.text('Kiểm lại các ô báo đỏ.'), findsOneWidget);
    expect(_errorOf(tester, 'Tên sản phẩm'), 'Cần nhập ô này.');
    await scrollTo(tester, _field('Năng lượng (kcal)'));
    expect(_errorOf(tester, 'Năng lượng (kcal)'), 'Cần nhập ô này.');
    expect(_errorOf(tester, 'Natri (mg, không bắt buộc)'), isNull);
    expect(find.byType(CustomProductFormScreen), findsOneWidget);
  });

  testWidgets('số không khớp (nhập kcal cả chai vào ô 100 ml): hỏi trước, "Kiểm lại" thì chưa lưu', (tester) async {
    await pumpFluwApp(tester, httpClient: _emptyBackend([]));
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Nhập sản phẩm từ nhãn'));

    await _enter(tester, 'Tên sản phẩm', 'Sữa đậu');
    await _enter(tester, 'Năng lượng (kcal)', '400');
    await _enter(tester, 'Protein (đạm) (g, không bắt buộc)', '3');
    await _enter(tester, 'Carb (bột đường) (g, không bắt buộc)', '5');
    await _enter(tester, 'Chất béo (g, không bắt buộc)', '2');
    await _save(tester);

    expect(find.text('Số liệu có vẻ chưa khớp'), findsOneWidget);
    await tester.tap(find.text('Kiểm lại'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomProductFormScreen), findsOneWidget);
    expect(
      await tester.runAsync(() => appContainer(tester).read(customProductRepositoryProvider).search('sữa')),
      isEmpty,
    );
  });

  testWidgets('mã đã có ở sản phẩm khác: báo dưới ô mã vạch, không lưu', (tester) async {
    await pumpFluwApp(tester, httpClient: _emptyBackend([]));
    await _saveStored(tester, _latte());
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Nhập sản phẩm từ nhãn'));

    await _enter(tester, 'Tên sản phẩm', 'Khác');
    await _enter(tester, 'Mã vạch (không bắt buộc)', _code);
    await _enter(tester, 'Năng lượng (kcal)', '10');
    await _save(tester);

    await scrollTo(tester, _field('Mã vạch (không bắt buộc)'), delta: -200);
    expect(_errorOf(tester, 'Mã vạch (không bắt buộc)'), 'Mã này đã có trong sản phẩm tự nhập: Trà sữa latte.');
    expect(find.byType(CustomProductFormScreen), findsOneWidget);
  });

  testWidgets('đã gõ mà bấm quay lại thì hỏi trước khi bỏ; chưa gõ gì thì không hỏi', (tester) async {
    await pumpFluwApp(tester, httpClient: _emptyBackend([]));
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Nhập sản phẩm từ nhãn'));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(CustomProductFormScreen), findsNothing);

    await _tapVisible(tester, find.text('Nhập sản phẩm từ nhãn'));
    await _enter(tester, 'Tên sản phẩm', 'A');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thông tin đã nhập?'), findsOneWidget);
    await tester.tap(find.text('Nhập tiếp'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomProductFormScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomProductFormScreen), findsNothing);
  });

  testWidgets('Tra Cứu: sản phẩm tự nhập đứng đầu, gõ không dấu vẫn ra, mất mạng vẫn ra', (tester) async {
    await pumpFluwApp(tester);
    await _saveStored(tester, _latte());
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'tra sua');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('1 kết quả cho "tra sua"'), findsOneWidget);
    expect(find.text('Trà sữa latte'), findsOneWidget);
    expect(find.textContaining('Chỉ hiện sản phẩm bạn tự nhập.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Thử lại'), findsOneWidget);
  });

  testWidgets('Tra Cứu có mạng: sản phẩm tự nhập trước kết quả của nguồn', (tester) async {
    await pumpFluwApp(
      tester,
      httpClient: MockClient(
        (request) async => _json(searchBody(request.url.queryParameters['q']!, [yoghurtSearchItem])),
      ),
    );
    await _saveStored(tester, _latte());
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'sữa');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final loaded = appContainer(tester).read(searchControllerProvider) as SearchLoaded;
    expect([for (final item in loaded.response.items) item.name], ['Trà sữa latte', yoghurtSearchItem['name']]);
    expect(find.text('Một nguồn dữ liệu đang lỗi nên có thể thiếu kết quả.'), findsNothing);
  });

  testWidgets('Chi tiết: sửa số liệu thì màn đổi theo; xóa thì hỏi, xóa xong quay về và không còn trên máy', (
    tester,
  ) async {
    await pumpFluwApp(tester, httpClient: _emptyBackend([]));
    await _saveStored(tester, _latte());
    await scan(tester, _code);
    expect(find.text('114 kcal cho 440 ml'), findsOneWidget, reason: 'không có khẩu phần thì mặc định cả chai');

    await tester.tap(find.byTooltip('Sửa sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa sản phẩm'), findsOneWidget);
    await _enter(tester, 'Năng lượng (kcal)', '30');
    await _save(tester);
    expect(find.text('132 kcal cho 440 ml'), findsOneWidget);
    expect((await _stored(tester, 'latte'))!.facts.per100[Nutrient.energyKcal], 30);

    await tester.tap(find.byTooltip('Xóa sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nhật Ký vẫn giữ nguyên số liệu'), findsOneWidget);
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();

    expect(find.byType(FoodDetailScreen), findsNothing);
    expect(find.text('Đã xóa Trà sữa latte.'), findsOneWidget);
    expect(await _stored(tester, 'latte'), isNull);
  });

  testWidgets('màn nhỏ 320×568, chữ 200%: form không tràn', (tester) async {
    await loadAppFonts();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpFluwApp(tester, httpClient: _emptyBackend([]));
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Nhập sản phẩm từ nhãn'));
    await _save(tester);
    for (var step = 0; step < 12; step++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('Tra Cứu: nguồn có sản phẩm cùng mã với sản phẩm tự nhập thì chỉ hiện bản tự nhập', (tester) async {
    await pumpFluwApp(
      tester,
      httpClient: MockClient(
        (request) async => _json(searchBody(request.url.queryParameters['q']!, [yoghurtSearchItem])),
      ),
    );
    final barcode = yoghurtSearchItem['barcode']! as String;
    await _saveStored(
      tester,
      CustomProduct(
        id: 'mine',
        name: 'Sữa chua dâu của tôi',
        brand: null,
        barcode: '0$barcode',
        facts: NutritionFacts(per100: Nutrients({Nutrient.energyKcal: 90}), unit: QuantityUnit.gram),
        packageAmount: null,
        servingAmount: null,
        labelPerServing: false,
      ),
    );
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'sữa chua');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final loaded = appContainer(tester).read(searchControllerProvider) as SearchLoaded;
    expect([for (final item in loaded.response.items) item.name], ['Sữa chua dâu của tôi']);
  });

  testWidgets('xóa từ Chi tiết mở từ Tra Cứu: quay về danh sách thì sản phẩm không còn', (tester) async {
    await pumpFluwApp(tester);
    await _saveStored(tester, _latte());
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'latte');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trà sữa latte'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xóa sản phẩm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();

    expect(find.byType(FoodDetailScreen), findsNothing);
    expect(find.text('0 kết quả cho "latte"'), findsOneWidget);
    expect(find.byType(FoodResultCard), findsNothing);
  });

  testWidgets('database lỗi: màn tra mã vẫn hỏi máy chủ, không thành màn lỗi trắng', (tester) async {
    final broken = AppDatabase(NativeDatabase.memory(setup: (_) => throw StateError('file database hỏng')));
    addTearDown(() => tester.runAsync(broken.close));
    await pumpFluwApp(
      tester,
      httpClient: MockClient((request) async => _json({'item': yoghurtProduct})),
      overrides: [customProductRepositoryProvider.overrideWithValue(CustomProductRepository(broken))],
    );
    await scan(tester, yoghurtProduct['barcode']! as String);

    expect(tester.takeException(), isNotNull, reason: 'lỗi database được báo lại, không bị nuốt im lặng');
    expect(find.byType(FoodDetailScreen), findsOneWidget);
    expect(find.text(yoghurtProduct['name']! as String), findsOneWidget);
  });

  testWidgets('quét mã A rồi sửa thành mã B trong form: lưu được, màn mã A không giả vờ là sản phẩm đó', (
    tester,
  ) async {
    await pumpFluwApp(tester, httpClient: _emptyBackend([]));
    await scan(tester, _code);
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Nhập từ nhãn'));

    await _enter(tester, 'Tên sản phẩm', 'Bánh quy');
    await _enter(tester, 'Mã vạch (không bắt buộc)', '96385074');
    await _enter(tester, 'Năng lượng (kcal)', '450');
    await _save(tester);

    expect(find.text('Đã lưu Bánh quy với mã khác mã $_code.'), findsOneWidget);
    expect(find.text('Chưa có sản phẩm này'), findsOneWidget);
    expect(
      (await tester.runAsync(
        () => appContainer(tester).read(customProductRepositoryProvider).findByBarcode('96385074'),
      ))?.name,
      'Bánh quy',
    );
  });
}
