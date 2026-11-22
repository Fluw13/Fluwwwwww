import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../profile/domain/profile_fixture.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

final Map<String, Object?> _noDataItem = {
  ...colaItem,
  'id': 'off:8930000000001',
  'name': 'Bánh quy không số liệu',
  'barcode': null,
  'servingSize': null,
  'nutrients': <String, Object?>{},
};

MockClient _backend(
  List<Map<String, Object?>> items, {
  List<Uri>? calls,
  Future<Map<String, Object?>> Function()? product,
}) => MockClient((request) async {
  calls?.add(request.url);
  if (request.url.path == '/api/foods/search') {
    return _json(searchBody(request.url.queryParameters['q']!, items));
  }
  return _json({'item': await (product?.call() ?? Future.value(yoghurtProduct))});
});

void main() {
  Future<void> openSearch(WidgetTester tester, MockClient backend) async {
    await pumpFluwApp(tester, httpClient: backend);
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
  }

  Future<void> searchFor(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField).first, query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

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

  Finder portionField() => find.widgetWithText(TextField, 'Khẩu phần bạn ăn');
  String portionText(WidgetTester tester) => tester.widget<TextField>(portionField()).controller!.text;

  testWidgets(
    'món không có số liệu giữ thứ tự nguồn; món OFF có mã thì "Mở để xem số liệu"; đồ tươi tìm thêm bằng tiếng Anh',
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final calls = <Uri>[];
      final offWithoutData = {
        ..._noDataItem,
        'id': 'off:8935001282266',
        'name': 'Latte trà sữa',
        'barcode': '8935001282266',
      };
      await openSearch(tester, _backend([offWithoutData, _noDataItem, chickenItem], calls: calls));

      await searchFor(tester, 'ức gà');

      expect(calls.single.queryParameters, {'q': 'ức gà', 'en': 'chicken breast'});
      expect(find.text('Đã tìm thêm bằng tiếng Anh: chicken breast'), findsOneWidget);
      expect(find.text('Mở để xem số liệu'), findsOneWidget, reason: 'màn Chi tiết tra mã vạch, thường có số liệu');
      expect(find.text('Chưa có số liệu'), findsOneWidget, reason: 'không có mã vạch thì không tra thêm được');
      expect(find.text('Chưa có'), findsNothing, reason: 'không còn ba ô "Chưa có" trên thẻ không có số liệu');
      expect(
        tester.getTopLeft(find.text('Latte trà sữa')).dy,
        lessThan(tester.getTopLeft(find.textContaining('Chicken, broiler')).dy),
        reason: 'chỉ mục tìm kiếm của OFF chậm cập nhật: món đúng thường chưa có số liệu, không đẩy xuống cuối',
      );
    },
  );

  testWidgets('lọc nhanh vẫn loại món chưa có số liệu và nói rõ số món đó', (tester) async {
    await openSearch(tester, _backend([_noDataItem, chickenItem]));
    await searchFor(tester, 'gà');

    await tester.tap(find.text('Protein ≥ 20 g'));
    await tester.pumpAndSettle();

    expect(find.text('Bánh quy không số liệu'), findsNothing);
    expect(
      find.textContaining('1 món chưa có số liệu trong kết quả tìm kiếm: bỏ lọc rồi mở món để xem.'),
      findsOneWidget,
    );
  });

  testWidgets('đồ đóng gói có từ lạ thì không gửi tiếng Anh, không hiện dòng tiếng Anh', (tester) async {
    final calls = <Uri>[];
    await openSearch(tester, _backend([yoghurtSearchItem], calls: calls));

    await searchFor(tester, 'sữa chua vinamilk');

    expect(calls.single.queryParameters, {'q': 'sữa chua vinamilk'});
    expect(find.textContaining('Đã tìm thêm bằng tiếng Anh'), findsNothing);
  });

  testWidgets('lọc "Đường ≤ 5 g": đồ uống phải ≤ 2.5 g trong 100 ml, có ghi chú khi đang lọc', (tester) async {
    final drink4g = {
      ...colaItem,
      'id': 'off:8930000000002',
      'name': 'Trà ít đường',
      'nutrients': {'energyKcal': 16, 'sugarsG': 4},
    };
    final drink2g = {
      ...colaItem,
      'id': 'off:8930000000003',
      'name': 'Trà rất ít đường',
      'nutrients': {'energyKcal': 8, 'sugarsG': 2},
    };
    await openSearch(tester, _backend([drink4g, drink2g, chickenItem]));
    await searchFor(tester, 'trà');
    expect(find.text('Dưới 200 kcal'), findsOneWidget);

    await tester.tap(find.text('Đường ≤ 5 g'));
    await tester.pumpAndSettle();

    expect(find.text('Đồ uống: đường ≤ 2.5 g trong 100 ml.'), findsOneWidget);
    expect(find.text('Trà ít đường'), findsNothing);
    expect(find.text('Trà rất ít đường'), findsOneWidget);
    expect(find.text('2 kết quả cho "trà"'), findsOneWidget);
  });

  testWidgets('máy chủ trả trang lỗi 502 (Render đang khởi động) thì nói máy chủ đang bận, không nói dữ liệu hỏng', (
    tester,
  ) async {
    await openSearch(tester, MockClient((request) async => http.Response('<html>Bad Gateway</html>', 502)));

    await searchFor(tester, 'phở');

    expect(find.text('Máy chủ đang khởi động hoặc bận, hãy thử lại sau ít phút.'), findsOneWidget);
    expect(find.textContaining('không đọc được'), findsNothing);
  });

  testWidgets('chi tiết: mặc định theo khẩu phần trên bao bì, chip khẩu phần đổi số trong ô', (tester) async {
    await openSearch(tester, _backend([colaItem], product: () async => colaItem));
    await searchFor(tester, 'coca');
    await tester.tap(find.text('Coca-Cola'));
    await tester.pumpAndSettle();
    expect(portionText(tester), '355');
    await scrollTo(tester, find.widgetWithText(ChoiceChip, '1 khẩu phần (355 ml)'));
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '1 khẩu phần (355 ml)')).selected, isTrue);

    await tester.tap(find.widgetWithText(ChoiceChip, '50 ml'));
    await tester.pumpAndSettle();
    expect(portionText(tester), '50');
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '50 ml')).selected, isTrue);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '1 khẩu phần (355 ml)')).selected, isFalse);
  });

  testWidgets('món chưa có khẩu phần trên bao bì: mặc định 100, sản phẩm đầy đủ mang khẩu phần thì đổi theo', (
    tester,
  ) async {
    final product = Completer<Map<String, Object?>>();
    await openSearch(tester, _backend([yoghurtSearchItem], product: () => product.future));
    await searchFor(tester, 'sữa chua');
    await tester.tap(find.text('Vinamilk sữa chua dâu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(portionText(tester), '100');
    expect(find.widgetWithText(ChoiceChip, '100 g'), findsOneWidget);

    product.complete({...yoghurtProduct, 'servingSize': '1 hũ (120 g)'});
    await tester.pumpAndSettle();

    expect(portionText(tester), '120');
    expect(find.widgetWithText(ChoiceChip, '1 khẩu phần (120 g)'), findsOneWidget);
  });

  testWidgets('khẩu phần người dùng đã gõ thì giữ, kể cả khi sản phẩm đầy đủ về sau mang khẩu phần', (tester) async {
    final product = Completer<Map<String, Object?>>();
    await openSearch(tester, _backend([yoghurtSearchItem], product: () => product.future));
    await searchFor(tester, 'sữa chua');
    await tester.tap(find.text('Vinamilk sữa chua dâu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(portionField(), '80');
    product.complete({...yoghurtProduct, 'servingSize': '1 hũ (120 g)'});
    await tester.pumpAndSettle();

    expect(portionText(tester), '80');
  });

  testWidgets('khẩu phần trống hoặc sai: đối chiếu hồ sơ nói nhập khẩu phần, không nói món thiếu số liệu', (
    tester,
  ) async {
    await openSearch(tester, _backend([chickenItem]));
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await tester.pumpAndSettle();
    await searchFor(tester, 'chicken');
    await tester.tap(find.textContaining('Chicken, broiler'));
    await tester.pumpAndSettle();

    await scrollTo(tester, portionField());
    await tester.enterText(portionField(), '');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Đối chiếu hồ sơ của bạn'), delta: -200);

    expect(find.text('Nhập khẩu phần hợp lệ để so với chỉ tiêu.'), findsOneWidget);
    expect(find.text('Chưa đủ số liệu của món để so với chỉ tiêu.'), findsNothing);
  });

  testWidgets('320x568 cỡ chữ 310%: nhãn "Chưa có số liệu", dòng tiếng Anh và chip khẩu phần không tràn', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await openSearch(tester, _backend([_noDataItem, colaItem], product: () async => colaItem));

    await searchFor(tester, 'cà chua');
    await scrollTo(tester, find.text('Chưa có số liệu'));
    expect(tester.takeException(), isNull);

    // The result named Coca-Cola, below the one without data (whose brand is also Coca-Cola).
    await scrollTo(tester, find.text('Coca-Cola').last);
    await tester.tap(find.text('Coca-Cola').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.widgetWithText(ChoiceChip, '200 ml'));
    expect(tester.takeException(), isNull);
  });
}
