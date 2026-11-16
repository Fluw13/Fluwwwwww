import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/features/search/presentation/barcode_lookup_screen.dart';
import 'package:fluw/features/search/presentation/food_detail_screen.dart';
import 'package:fluw/features/search/presentation/search_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

/// Answers every barcode with the yoghurt product, or with "not found" for [missing].
MockClient _backend({List<Uri>? calls, String? missing}) => MockClient((request) async {
  calls?.add(request.url);
  if (missing != null && request.url.path.endsWith('/$missing')) {
    return _json({
      'error': {'code': 'PRODUCT_NOT_FOUND', 'message': 'Không tìm thấy sản phẩm.'},
    }, 404);
  }
  return _json({'item': yoghurtProduct});
});

/// Taps after scrolling the finder into view: the square camera can push the rest of the page below the fold.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  Future<void> openScan(WidgetTester tester) async {
    await tester.tap(find.text(AppTab.scan.label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('camera chỉ chạy khi đang ở tab Quét', (tester) async {
    await pumpFluwApp(tester, httpClient: _backend());
    await openScan(tester);
    final camera = appBarcodeCamera(tester);
    expect(camera.isActive, isTrue);

    await tester.tap(find.text(AppTab.home.label).last);
    await tester.pumpAndSettle();
    expect(camera.isActive, isFalse, reason: 'tab Quét vẫn giữ trạng thái nhưng camera phải tắt');
  });

  testWidgets('quét được mã: mở sản phẩm đầy đủ (một lượt gọi), camera tắt khi đang xem, quay lại thì chạy lại', (
    tester,
  ) async {
    final calls = <Uri>[];
    await pumpFluwApp(tester, httpClient: _backend(calls: calls));
    await openScan(tester);
    final camera = appBarcodeCamera(tester);

    camera.scan(yoghurtProduct['barcode']! as String);
    await tester.pumpAndSettle();

    expect(find.byType(FoodDetailScreen), findsOneWidget);
    expect(find.text(yoghurtProduct['name']! as String), findsOneWidget);
    expect(calls, hasLength(1), reason: 'màn Chi tiết không tra lại mã vạch đã tra');
    expect(camera.isActive, isFalse);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(camera.isActive, isTrue);
  });

  testWidgets('camera đọc nhầm (sai chữ số kiểm tra) thì bỏ qua, không gọi máy chủ', (tester) async {
    final calls = <Uri>[];
    await pumpFluwApp(tester, httpClient: _backend(calls: calls));
    await openScan(tester);

    appBarcodeCamera(tester).scan('8934673607828');
    await tester.pumpAndSettle();

    expect(find.byType(BarcodeLookupScreen), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('chưa có sản phẩm: nói rõ và cho tìm theo tên', (tester) async {
    await pumpFluwApp(tester, httpClient: _backend(missing: '96385074'));
    await openScan(tester);

    appBarcodeCamera(tester).scan('96385074');
    await tester.pumpAndSettle();
    expect(find.text('Chưa có sản phẩm này'), findsOneWidget);

    await _tapVisible(tester, find.text('Tìm theo tên'));
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('lỗi mạng khi tra mã: báo lỗi và thử lại được', (tester) async {
    var attempt = 0;
    final backend = MockClient((request) async {
      attempt++;
      if (attempt == 1) {
        throw http.ClientException('mất mạng');
      }
      return _json({'item': yoghurtProduct});
    });
    await pumpFluwApp(tester, httpClient: backend);
    await openScan(tester);

    appBarcodeCamera(tester).scan(yoghurtProduct['barcode']! as String);
    await tester.pumpAndSettle();
    expect(find.text('Chưa tra được mã'), findsOneWidget);

    await _tapVisible(tester, find.text('Thử lại'));
    expect(find.byType(FoodDetailScreen), findsOneWidget);
  });

  testWidgets('nhập mã bằng tay: mã sai thì báo, mã đúng thì mở sản phẩm', (tester) async {
    await pumpFluwApp(tester, httpClient: _backend());
    await openScan(tester);

    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Mã vạch (8–14 chữ số)'), 300);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Mã vạch (8–14 chữ số)'), '12345');
    await _tapVisible(tester, find.text('Tra mã'));
    expect(find.textContaining('8, 12, 13 hoặc 14 chữ số'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Mã vạch (8–14 chữ số)'),
      yoghurtProduct['barcode']! as String,
    );
    await _tapVisible(tester, find.text('Tra mã'));
    expect(find.byType(FoodDetailScreen), findsOneWidget);
  });

  testWidgets('320x568 cỡ chữ 310%: màn Quét không tràn', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await pumpFluwApp(tester, httpClient: _backend());
    await openScan(tester);

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
