import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/scan/data/food_photo_picker.dart';
import 'package:fluw/features/scan/data/photo_consent_storage.dart';
import 'package:fluw/features/scan/data/recognition_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  test('gửi đúng byte ảnh và kiểu ảnh lên /api/foods/recognize, đọc tên món', () async {
    final requests = <http.Request>[];
    final result = await _api({
      'isFood': true,
      'foods': [
        {'name': 'Phở bò', 'searchQuery': 'phở bò'},
      ],
    }, requests: requests).recognize([1, 2, 3], contentType: 'image/png');

    expect(requests.single.method, 'POST');
    expect(requests.single.url.toString(), 'https://api.test/api/foods/recognize');
    expect(requests.single.headers['Content-Type'], 'image/png');
    expect(requests.single.bodyBytes, [1, 2, 3]);
    expect(result.isFood, isTrue);
    expect(result.foods.single.name, 'Phở bò');
    expect(result.foods.single.searchQuery, 'phở bò');
  });

  test('bỏ món sai dạng (thiếu tên, từ khóa dưới 2 ký tự); không còn món nào thì không phải đồ ăn', () async {
    final result = await _api({
      'isFood': true,
      'foods': [
        {'name': ' ', 'searchQuery': 'cơm'},
        {'name': 'Cơm', 'searchQuery': 'c'},
        {'name': 'Cơm tấm', 'searchQuery': 42},
      ],
    }).recognize([1], contentType: 'image/jpeg');

    expect(result.foods, isEmpty);
    expect(result.isFood, isFalse);
  });

  test('máy chủ trả sai dạng thì phản hồi không đọc được; lỗi có mã thì giữ lời nhắn', () async {
    await expectLater(
      _api({'foods': 'x'}).recognize([1], contentType: 'image/jpeg'),
      throwsA(isA<InvalidResponseFailure>()),
    );
    await expectLater(
      _api({
        'error': {'code': 'RECOGNITION_BUSY', 'message': 'Đã hết lượt.'},
      }, status: 503).recognize([1], contentType: 'image/jpeg'),
      throwsA(isA<ServerFailure>().having((failure) => failure.code, 'code', 'RECOGNITION_BUSY')),
    );
  });

  test('kiểu ảnh: lấy theo mime của file, không có thì theo đuôi; đuôi lạ coi là JPEG', () {
    expect(contentTypeOf('a.jpg', 'image/heic'), 'image/heic');
    expect(contentTypeOf('a.PNG', null), 'image/png');
    expect(contentTypeOf('a.webp', null), 'image/webp');
    expect(contentTypeOf('a.heic', 'application/octet-stream'), 'image/heic');
    expect(contentTypeOf('a.jpeg', null), 'image/jpeg');
    expect(contentTypeOf('image_picker_123', null), 'image/jpeg');
  });

  test('đồng ý gửi ảnh: mặc định chưa, đồng ý thì nhớ; không có kho thì luôn hỏi lại', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = PhotoConsentStorage(await SharedPreferences.getInstance());
    expect(storage.hasConsent, isFalse);

    await storage.giveConsent();
    expect(storage.hasConsent, isTrue);
    expect(PhotoConsentStorage(await SharedPreferences.getInstance()).hasConsent, isTrue);

    const noStore = PhotoConsentStorage(null);
    await noStore.giveConsent();
    expect(noStore.hasConsent, isFalse);
  });
}
