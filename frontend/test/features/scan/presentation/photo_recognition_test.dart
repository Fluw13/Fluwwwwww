import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/search/search_request.dart';
import 'package:fluw/features/scan/data/food_photo_picker.dart';
import 'package:fluw/features/scan/data/photo_consent_storage.dart';
import 'package:fluw/features/search/presentation/search_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

const Map<String, Object?> _pho = {
  'isFood': true,
  'foods': [
    {'name': 'Phở bò', 'searchQuery': 'phở bò'},
    {'name': 'Rau thơm', 'searchQuery': 'rau thơm'},
  ],
};

void main() {
  Future<void> openPhotoMode(WidgetTester tester) async {
    await tester.tap(find.text(AppTab.scan.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ảnh món ăn'));
    await tester.pumpAndSettle();
  }

  testWidgets('lần đầu hỏi đồng ý gửi ảnh; không đồng ý thì không mở camera, không gửi gì', (tester) async {
    final requests = <http.Request>[];
    await pumpFluwApp(tester, httpClient: MockClient((request) async => (requests..add(request), _json(_pho)).$2));
    await openPhotoMode(tester);

    await tester.tap(find.text('Chụp ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi ảnh để nhận diện món?'), findsOneWidget);
    expect(find.textContaining('Google có thể dùng ảnh'), findsOneWidget);

    await tester.tap(find.text('Không'));
    await tester.pumpAndSettle();
    expect(appPhotoPicker(tester).requests, isEmpty);
    expect(requests, isEmpty);
  });

  testWidgets('đồng ý: chụp, gửi ảnh, hiện tên món kèm ghi chú AI; lần sau không hỏi lại; chọn món thì tra cứu', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final preferences = await pumpFluwApp(
      tester,
      httpClient: MockClient((request) async {
        requests.add(request);
        return request.url.path.endsWith('/recognize') ? _json(_pho) : _json(searchBody('phở bò', [yoghurtSearchItem]));
      }),
    );
    await openPhotoMode(tester);

    await tester.tap(find.text('Chụp ảnh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();

    expect(preferences.getBool(PhotoConsentStorage.key), isTrue);
    expect(appPhotoPicker(tester).requests, [PhotoSource.camera]);
    expect(requests.single.headers['Content-Type'], 'image/jpeg');
    expect(requests.single.bodyBytes, [1, 2, 3]);
    expect(find.textContaining('AI (Google Gemini) gợi ý, có thể sai'), findsOneWidget);
    expect(find.text('Phở bò'), findsOneWidget);
    expect(find.text('Rau thơm'), findsOneWidget);

    await tester.tap(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi ảnh để nhận diện món?'), findsNothing, reason: 'đã đồng ý thì không hỏi lại');
    expect(appPhotoPicker(tester).requests, [PhotoSource.camera, PhotoSource.gallery]);

    await tester.tap(find.text('Phở bò'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(requests.last.url.queryParameters['q'], 'phở bò');
    expect(find.widgetWithText(TextField, 'phở bò'), findsOneWidget);
    expect(find.text(yoghurtSearchItem['name']! as String), findsOneWidget);
    expect(appContainer(tester).read(searchRequestProvider), isNull, reason: 'yêu cầu tra cứu chỉ chạy một lần');
  });

  testWidgets('đang nhận diện thì tắt nút và báo chờ; ảnh không có món ăn thì nói rõ', (tester) async {
    final answer = Completer<http.Response>();
    await pumpFluwApp(
      tester,
      storedSettings: {PhotoConsentStorage.key: true},
      httpClient: MockClient((request) => answer.future),
    );
    await openPhotoMode(tester);

    await tester.tap(find.text('Chọn ảnh'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('Đang nhận diện'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Chụp ảnh')).onPressed, isNull);

    answer.complete(_json({'isFood': false, 'foods': <Object>[]}));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không thấy món ăn trong ảnh'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Chụp ảnh')).onPressed, isNotNull);
  });

  testWidgets('lỗi máy chủ thì hiện lời nhắn của máy chủ; ảnh quá lớn (413) thì nói rõ; huỷ chọn ảnh thì không gửi', (
    tester,
  ) async {
    var status = 503;
    final requests = <http.Request>[];
    await pumpFluwApp(
      tester,
      storedSettings: {PhotoConsentStorage.key: true},
      httpClient: MockClient((request) async {
        requests.add(request);
        return _json({
          'error': {'code': status == 413 ? 'BAD_REQUEST' : 'RECOGNITION_BUSY', 'message': 'Đã hết lượt nhận diện.'},
        }, status);
      }),
    );
    await openPhotoMode(tester);

    await tester.tap(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hết lượt nhận diện.'), findsOneWidget);

    status = 413;
    await tester.tap(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Ảnh quá lớn. Hãy chọn ảnh khác hoặc chụp lại.'), findsOneWidget);

    appPhotoPicker(tester).next = null;
    await tester.tap(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(2), reason: 'huỷ chọn ảnh thì không gửi gì');
  });

  testWidgets('320x568 cỡ chữ 310%: hộp đồng ý và danh sách món không tràn', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await pumpFluwApp(tester, httpClient: MockClient((request) async => _json(_pho)));
    await openPhotoMode(tester);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(AlertDialog), const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Rau thơm'), findsOneWidget);
  });

  testWidgets('chế độ ảnh tắt camera quét mã; về Mã vạch thì camera chạy lại', (tester) async {
    await pumpFluwApp(tester);
    await tester.tap(find.text(AppTab.scan.label).last);
    await tester.pumpAndSettle();
    expect(appBarcodeCamera(tester).isActive, isTrue);

    await tester.tap(find.text('Ảnh món ăn'));
    await tester.pumpAndSettle();
    expect(find.text('Camera đang chạy'), findsNothing);

    await tester.tap(find.text('Mã vạch'));
    await tester.pumpAndSettle();
    expect(find.text('Camera đang chạy'), findsOneWidget);
  });
}
