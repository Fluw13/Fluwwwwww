import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/search/search_request.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/scan/data/food_photo_picker.dart';
import 'package:fluw/features/scan/data/photo_consent_storage.dart';
import 'package:fluw/features/scan/domain/photo_metadata.dart';
import 'package:fluw/features/search/presentation/search_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../fixtures/food_api_samples.dart';
import '../../../helpers/fake_food_photo_picker.dart';
import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../profile/domain/profile_fixture.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

const Map<String, Object?> _pho = {
  'isFood': true,
  'foods': [
    {'name': 'Phở bò', 'searchQuery': 'phở bò', 'searchQueryEn': 'beef pho'},
    {'name': 'Rau thơm', 'searchQuery': 'rau thơm', 'searchQueryEn': 'herbs'},
  ],
};

void main() {
  Future<void> saveProfile(WidgetTester tester, HealthProfile profile) async {
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(profile));
    await tester.pumpAndSettle();
  }

  /// The photo mode with an adult profile (born 2006, 20 on the test day).
  Future<void> openPhotoMode(WidgetTester tester, {HealthProfile? profile}) async {
    await saveProfile(tester, profile ?? buildProfile());
    await tester.tap(find.text(AppTab.scan.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ảnh món ăn'));
    await tester.pumpAndSettle();
  }

  testWidgets('chỉ người từ 18 tuổi mới dùng được: chưa có hồ sơ hoặc dưới 18 tuổi thì không có nút gửi ảnh', (
    tester,
  ) async {
    await pumpFluwApp(tester);
    await tester.tap(find.text(AppTab.scan.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ảnh món ăn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('chỉ dành cho người từ 18 tuổi. Hãy thiết lập hồ sơ'), findsOneWidget);
    expect(find.text('Chụp ảnh'), findsNothing);

    await saveProfile(tester, buildProfile(birthDate: CalendarDate(2009, 1, 1)));
    expect(find.textContaining('theo điều khoản của Google'), findsOneWidget);
    expect(find.text('Chụp ảnh'), findsNothing);

    await saveProfile(tester, buildProfile(birthDate: CalendarDate(2008, 11, 11)));
    expect(find.text('Chụp ảnh'), findsOneWidget, reason: 'tròn 18 tuổi đúng ngày test');
  });

  testWidgets('lần đầu hỏi đồng ý gửi ảnh; không đồng ý thì không mở camera, không gửi gì', (tester) async {
    final requests = <http.Request>[];
    await pumpFluwApp(tester, httpClient: MockClient((request) async => (requests..add(request), _json(_pho)).$2));
    await openPhotoMode(tester);

    await tester.tap(find.text('Chụp ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi ảnh để nhận diện món?'), findsOneWidget);
    expect(find.textContaining('xóa thông tin vị trí'), findsOneWidget);
    expect(find.textContaining('cho người xem lại'), findsOneWidget);

    await tester.tap(find.text('Không'));
    await tester.pumpAndSettle();
    expect(appPhotoPicker(tester).requests, isEmpty);
    expect(requests, isEmpty);
  });

  testWidgets(
    'đồng ý: chụp, gửi ảnh đã xóa vị trí, hiện tên món kèm ghi chú AI; chọn món thì tra cả USDA bằng tiếng Anh',
    (tester) async {
      final requests = <http.Request>[];
      final preferences = await pumpFluwApp(
        tester,
        httpClient: MockClient((request) async {
          requests.add(request);
          return request.url.path.endsWith('/recognize')
              ? _json(_pho)
              : _json(searchBody('phở bò', [yoghurtSearchItem]));
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
      expect(requests.single.bodyBytes, removePhotoMetadata(FakeFoodPhotoPicker.photoWithLocation)!.bytes);
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
      expect(requests.last.url.queryParameters, {'q': 'phở bò', 'en': 'beef pho'});
      expect(find.widgetWithText(TextField, 'phở bò'), findsOneWidget);
      expect(find.text(yoghurtSearchItem['name']! as String), findsOneWidget);
      expect(appContainer(tester).read(searchRequestProvider), isNull, reason: 'yêu cầu tra cứu chỉ chạy một lần');
    },
  );

  testWidgets('đang mở camera hay đang nhận diện thì tắt cả hai nút; ảnh không có món ăn thì nói rõ', (tester) async {
    final answer = Completer<http.Response>();
    await pumpFluwApp(
      tester,
      storedSettings: {PhotoConsentStorage.key: true},
      httpClient: MockClient((request) => answer.future),
    );
    await openPhotoMode(tester);
    final picker = appPhotoPicker(tester)..hold = Completer<void>();
    bool enabled(String label) => tester
        .widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
          ),
        )
        .enabled;

    await tester.tap(find.text('Chọn ảnh'));
    await tester.pump();
    expect(enabled('Chụp ảnh') || enabled('Chọn ảnh'), isFalse, reason: 'bấm hai lần khi máy đang mở thư viện ảnh');

    picker.hold!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('Đang nhận diện'), findsOneWidget);
    expect(enabled('Chụp ảnh') || enabled('Chọn ảnh'), isFalse);

    answer.complete(_json({'isFood': false, 'foods': <Object>[]}));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không thấy món ăn trong ảnh'), findsOneWidget);
    expect(enabled('Chụp ảnh') && enabled('Chọn ảnh'), isTrue);
  });

  testWidgets(
    'lỗi máy chủ, ảnh quá lớn (413), không mở được camera, ảnh không phải JPEG/PNG; huỷ chọn ảnh thì không gửi',
    (tester) async {
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
      final picker = appPhotoPicker(tester);
      Future<void> pick() async {
        await tester.tap(find.text('Chọn ảnh'));
        await tester.pumpAndSettle();
      }

      await pick();
      expect(find.text('Đã hết lượt nhận diện.'), findsOneWidget);

      status = 413;
      await pick();
      expect(find.text('Ảnh quá lớn. Hãy chọn ảnh khác hoặc chụp lại.'), findsOneWidget);

      picker.error = StateError('camera_access_denied');
      await pick();
      expect(find.textContaining('Không mở được camera hoặc thư viện ảnh'), findsOneWidget);

      picker
        ..error = null
        ..next = utf8.encode('GIF89a');
      await pick();
      expect(find.textContaining('Ảnh dạng này chưa gửi được'), findsOneWidget);

      picker.next = null;
      await pick();
      expect(requests, hasLength(2), reason: 'ảnh GIF và huỷ chọn ảnh không gửi gì');
    },
  );

  testWidgets('rút lại đồng ý thì lần gửi sau hỏi lại', (tester) async {
    final preferences = await pumpFluwApp(
      tester,
      storedSettings: {PhotoConsentStorage.key: true},
      httpClient: MockClient((request) async => _json(_pho)),
    );
    await openPhotoMode(tester);

    await tester.tap(find.text('Rút lại đồng ý gửi ảnh'));
    await tester.pumpAndSettle();
    expect(preferences.getBool(PhotoConsentStorage.key), isNull);
    expect(find.text('Rút lại đồng ý gửi ảnh'), findsNothing);

    await tester.tap(find.text('Chọn ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi ảnh để nhận diện món?'), findsOneWidget);
  });

  testWidgets(
    'đổi qua Mã vạch rồi quay lại thì kết quả nhận diện vẫn còn; trạng thái được đọc cho trình đọc màn hình',
    (tester) async {
      await pumpFluwApp(
        tester,
        storedSettings: {PhotoConsentStorage.key: true},
        httpClient: MockClient((request) async => _json(_pho)),
      );
      await openPhotoMode(tester);
      await tester.tap(find.text('Chọn ảnh'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mã vạch').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ảnh món ăn').first);
      await tester.pumpAndSettle();

      expect(find.text('Phở bò'), findsOneWidget);
      final live = find.ancestor(
        of: find.text('Phở bò'),
        matching: find.byWidgetPredicate((widget) => widget is Semantics && (widget.properties.liveRegion ?? false)),
      );
      expect(live, findsOneWidget);
    },
  );

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

    await tester.drag(find.byType(ListView).last, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Rau thơm'), findsOneWidget);
  });

  testWidgets('chế độ ảnh tắt camera quét mã; về Mã vạch thì camera chạy lại', (tester) async {
    await pumpFluwApp(tester);
    await tester.tap(find.text(AppTab.scan.label).last);
    await tester.pumpAndSettle();
    expect(appBarcodeCamera(tester).isActive, isTrue);

    await tester.tap(find.text('Ảnh món ăn').first);
    await tester.pumpAndSettle();
    expect(appBarcodeCamera(tester).isActive, isFalse);

    await tester.tap(find.text('Mã vạch').first);
    await tester.pumpAndSettle();
    expect(appBarcodeCamera(tester).isActive, isTrue);
  });
}
