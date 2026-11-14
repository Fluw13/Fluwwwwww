import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../profile/domain/profile_fixture.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

/// Answers the search with [items] and every barcode with the full yoghurt product.
MockClient _backend(List<Map<String, Object?>> items, {List<Uri>? calls, String usda = 'ok'}) =>
    MockClient((request) async {
      calls?.add(request.url);
      if (request.url.path == '/api/foods/search') {
        return _json(searchBody(request.url.queryParameters['q']!, items, usda: usda));
      }
      return _json({'item': yoghurtProduct});
    });

void main() {
  Future<void> openSearch(WidgetTester tester, MockClient backend, {Map<String, Object> settings = const {}}) async {
    await pumpFluwApp(tester, httpClient: backend, storedSettings: settings);
    await tester.tap(find.text(AppTab.search.label).last);
    await tester.pumpAndSettle();
  }

  Future<void> searchFor(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField).first, query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    final list = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical).hitTestable();
    final element = list.evaluate().first;
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byElementPredicate((e) => identical(e, element)));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('tìm kiếm hiện kết quả từ cả hai nguồn, số liệu theo 100 g/ml, và lưu vào Gần đây', (tester) async {
    final calls = <Uri>[];
    await openSearch(tester, _backend([yoghurtSearchItem, colaItem, chickenItem], calls: calls));

    await searchFor(tester, '  sữa   chua ');

    expect(calls.single.queryParameters['q'], 'sữa chua');
    expect(find.text('3 kết quả cho "sữa chua"'), findsOneWidget);
    expect(find.text('Vinamilk sữa chua dâu'), findsOneWidget);
    expect(find.text('14.7 g'), findsOneWidget);
    expect(find.text('Gần đây'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'sữa chua'), findsOneWidget);
    await scrollTo(tester, find.text('Trong 100 ml'));
    expect(find.text('Trong 100 ml'), findsOneWidget);
  });

  testWidgets('lọc nhanh "Giàu protein" ẩn món không đạt và nói rõ số món bị ẩn', (tester) async {
    await openSearch(tester, _backend([yoghurtSearchItem, colaItem, chickenItem]));
    await searchFor(tester, 'thịt');

    await tester.tap(find.text('Giàu protein (>20 g)'));
    await tester.pumpAndSettle();

    expect(find.text('1 kết quả cho "thịt"'), findsOneWidget);
    expect(find.text('Đã ẩn 2 món không đạt bộ lọc hoặc thiếu số liệu để lọc.'), findsOneWidget);
    expect(find.text('Coca-Cola'), findsNothing);
  });

  testWidgets('một nguồn lỗi thì báo có thể thiếu kết quả', (tester) async {
    await openSearch(tester, _backend([yoghurtSearchItem], usda: 'unavailable'));
    await searchFor(tester, 'sữa');

    expect(find.text('Một nguồn dữ liệu đang lỗi nên có thể thiếu kết quả.'), findsOneWidget);
  });

  testWidgets('lỗi từ máy chủ hiện lời nhắn của máy chủ và cho thử lại', (tester) async {
    var attempt = 0;
    final backend = MockClient((request) async {
      attempt++;
      if (attempt == 1) {
        return _json({
          'error': {'code': 'TOO_MANY_REQUESTS', 'message': 'Bạn tra cứu quá nhanh, vui lòng thử lại sau ít phút.'},
        }, 429);
      }
      return _json(searchBody('phở', [chickenItem]));
    });
    await openSearch(tester, backend);
    await searchFor(tester, 'phở');

    expect(find.text('Bạn tra cứu quá nhanh, vui lòng thử lại sau ít phút.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('1 kết quả cho "phở"'), findsOneWidget);
  });

  testWidgets('máy chủ chậm (đang khởi động) thì sau vài giây giải thích vì sao phải chờ', (tester) async {
    final answer = Completer<http.Response>();
    await openSearch(tester, MockClient((request) => answer.future));

    await tester.enterText(find.byType(TextField).first, 'phở');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Máy chủ đang khởi động'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    expect(find.textContaining('Máy chủ đang khởi động'), findsOneWidget);

    answer.complete(_json(searchBody('phở', [chickenItem])));
    await tester.pumpAndSettle();
    expect(find.text('1 kết quả cho "phở"'), findsOneWidget);
  });

  testWidgets('chạm chip Gần đây thì tìm lại; xóa chip và Xóa tất cả', (tester) async {
    final calls = <Uri>[];
    await openSearch(
      tester,
      _backend([chickenItem], calls: calls),
      settings: {
        'recent_searches': ['phở', 'bún bò'],
      },
    );

    await tester.tap(find.widgetWithText(InputChip, 'bún bò'));
    await tester.pumpAndSettle();
    expect(calls.single.queryParameters['q'], 'bún bò');

    await tester.tap(find.byTooltip('Xóa "phở" khỏi gần đây'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'phở'), findsNothing);

    await tester.tap(find.text('Xóa tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('Gần đây'), findsNothing);
  });

  testWidgets('chi tiết: tải sản phẩm đầy đủ, cảnh báo dị ứng nặng theo hồ sơ, đổi khẩu phần thì số liệu đổi theo', (
    tester,
  ) async {
    final calls = <Uri>[];
    await openSearch(tester, _backend([yoghurtSearchItem], calls: calls));
    await tester.runAsync(
      () => appContainer(tester)
          .read(profileRepositoryProvider)
          .save(
            buildProfile(
              conditions: {HealthCondition.diabetes},
              dietary: DietaryPreferences(
                allergies: {Allergen.milk: AllergySeverity.severe},
                allergyNote: null,
                dietStyle: DietStyle.regular,
                preferences: const {},
              ),
            ),
          ),
    );
    await tester.pumpAndSettle();
    await searchFor(tester, 'sữa chua');

    await tester.tap(find.text('Vinamilk sữa chua dâu'));
    await tester.pumpAndSettle();

    expect(calls.last.path, '/api/foods/barcode/8934673607827');
    expect(find.text('Có thành phần bạn dị ứng nặng: Sữa.'), findsOneWidget);
    expect(find.text('Khẩu phần ghi trên bao bì: 1 portion (100 g)'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'), '200');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('29.4 g'));
    expect(find.text('29.4 g'), findsOneWidget);
    expect(find.text('Chưa có dữ liệu'), findsWidgets);
  });

  testWidgets('chi tiết món USDA: không có dữ liệu dị ứng thì nói rõ, không coi là an toàn', (tester) async {
    await openSearch(tester, _backend([chickenItem]));
    await tester.runAsync(
      () => appContainer(tester)
          .read(profileRepositoryProvider)
          .save(
            buildProfile(
              dietary: DietaryPreferences(
                allergies: {Allergen.eggs: AllergySeverity.mild},
                allergyNote: null,
                dietStyle: DietStyle.regular,
                preferences: const {},
              ),
            ),
          ),
    );
    await tester.pumpAndSettle();
    await searchFor(tester, 'chicken');

    await tester.tap(find.textContaining('Chicken, broiler'));
    await tester.pumpAndSettle();

    expect(find.text('Nguồn này không có dữ liệu dị ứng. Hãy đọc nhãn sản phẩm.'), findsOneWidget);
    await scrollTo(tester, find.textContaining('USDA FoodData Central (CC0 1.0)'));
    expect(find.textContaining('USDA FoodData Central (CC0 1.0)'), findsOneWidget);
  });

  testWidgets('khẩu phần sai thì báo lỗi, không hiện số bịa', (tester) async {
    await openSearch(tester, _backend([chickenItem]));
    await searchFor(tester, 'chicken');
    await tester.tap(find.textContaining('Chicken, broiler'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Khẩu phần bạn ăn'), '0');
    await tester.pumpAndSettle();

    expect(find.text('Nhập từ 1 đến 2,000 g.'), findsOneWidget);
    expect(find.text('–'), findsWidgets);
  });

  testWidgets('chưa có hồ sơ thì mời thiết lập để xem phần trăm chỉ tiêu', (tester) async {
    await openSearch(tester, _backend([chickenItem]));
    await searchFor(tester, 'chicken');
    await tester.tap(find.textContaining('Chicken, broiler'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thiết lập hồ sơ (từ 18 tuổi)'), findsOneWidget);
  });

  for (final textScale in [2.0, 3.1]) {
    testWidgets('320x568, cỡ chữ ${(textScale * 100).round()}%: Tra cứu và Chi tiết không tràn bố cục', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await loadAppFonts();

      await openSearch(
        tester,
        _backend([yoghurtSearchItem, chickenItem]),
        settings: {
          'recent_searches': ['sữa chua có đường'],
        },
      );
      await searchFor(tester, 'sữa chua');
      await scrollTo(tester, find.text('Vinamilk sữa chua dâu'));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Vinamilk sữa chua dâu'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.textContaining('Nguồn: Open Food Facts'));
      expect(tester.takeException(), isNull);
    });
  }
}
