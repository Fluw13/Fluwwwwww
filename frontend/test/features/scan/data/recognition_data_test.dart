import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/scan/data/photo_consent_storage.dart';
import 'package:fluw/features/scan/data/recognition_api.dart';
import 'package:fluw/features/scan/domain/photo_metadata.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_food_photo_picker.dart';

RecognitionApi _api(Object body, {int status = 200, List<http.Request>? requests}) => RecognitionApi(
  ApiClient(
    httpClient: MockClient((request) async {
      requests?.add(request);
      return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
    }),
    baseUri: Uri.parse('https://api.test'),
    timeout: const Duration(seconds: 5),
  ),
);

void main() {
  final photo = FakeFoodPhotoPicker.photoWithLocation;

  test('gửi ảnh đã xóa thông tin vị trí lên /api/foods/recognize, kiểu ảnh đọc từ nội dung; đọc tên món', () async {
    final requests = <http.Request>[];
    final result = await _api({
      'isFood': true,
      'foods': [
        {'name': 'Phở bò', 'searchQuery': 'phở bò', 'searchQueryEn': ' beef pho '},
        {'name': 'Rau thơm', 'searchQuery': 'rau thơm', 'searchQueryEn': null},
      ],
    }, requests: requests).recognize(photo);

    expect(requests.single.method, 'POST');
    expect(requests.single.url.toString(), 'https://api.test/api/foods/recognize');
    expect(requests.single.headers['Content-Type'], 'image/jpeg');
    expect(requests.single.bodyBytes, removePhotoMetadata(photo)!.bytes);
    expect(requests.single.bodyBytes.length, lessThan(photo.length));
    expect(result.isFood, isTrue);
    expect(result.foods.first.name, 'Phở bò');
    expect(result.foods.first.englishQuery, 'beef pho');
    expect(result.foods.last.englishQuery, isNull);
  });

  test('ảnh không phải JPEG/PNG thì không gửi gì', () async {
    final requests = <http.Request>[];

    await expectLater(
      _api(const {}, requests: requests).recognize(utf8.encode('GIF89a')),
      throwsA(isA<UnsupportedPhotoFormat>()),
    );
    expect(requests, isEmpty);
  });

  test('bỏ món sai dạng (thiếu tên, từ khóa dưới 2 ký tự); không còn món nào thì không phải đồ ăn', () async {
    final result = await _api({
      'isFood': true,
      'foods': [
        {'name': ' ', 'searchQuery': 'cơm'},
        {'name': 'Cơm', 'searchQuery': 'c'},
        {'name': 'Cơm tấm', 'searchQuery': 42},
      ],
    }).recognize(photo);

    expect(result.foods, isEmpty);
    expect(result.isFood, isFalse);
  });

  test('máy chủ trả sai dạng thì phản hồi không đọc được; lỗi có mã thì giữ lời nhắn', () async {
    await expectLater(_api({'foods': 'x'}).recognize(photo), throwsA(isA<InvalidResponseFailure>()));
    await expectLater(
      _api({
        'error': {'code': 'RECOGNITION_BUSY', 'message': 'Đã hết lượt.'},
      }, status: 503).recognize(photo),
      throwsA(isA<ServerFailure>().having((failure) => failure.code, 'code', 'RECOGNITION_BUSY')),
    );
  });

  test('đồng ý gửi ảnh: mặc định chưa, đồng ý thì nhớ, rút lại thì hỏi lại; không có kho thì luôn hỏi', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = PhotoConsentStorage(await SharedPreferences.getInstance());
    expect(storage.hasConsent, isFalse);

    await storage.giveConsent();
    expect(storage.hasConsent, isTrue);
    expect(PhotoConsentStorage(await SharedPreferences.getInstance()).hasConsent, isTrue);

    await storage.withdrawConsent();
    expect(storage.hasConsent, isFalse);

    SharedPreferences.setMockInitialValues({PhotoConsentStorage.legacyKey: true});
    expect(PhotoConsentStorage(await SharedPreferences.getInstance()).hasConsent, isFalse, reason: 'chữ cũ');
    SharedPreferences.setMockInitialValues({PhotoConsentStorage.key: PhotoConsentStorage.currentVersion - 1});
    expect(PhotoConsentStorage(await SharedPreferences.getInstance()).hasConsent, isFalse, reason: 'phiên bản cũ');

    const noStore = PhotoConsentStorage(null);
    await noStore.giveConsent();
    expect(noStore.hasConsent, isFalse);
  });
}
