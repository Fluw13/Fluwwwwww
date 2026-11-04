import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/api/api_config.dart';

void main() {
  test('mặc định là máy chủ Render', () {
    expect(
      ApiConfig.fromEnvironment().origin.toString(),
      ApiConfig.defaultOrigin,
    );
  });

  test('nhận origin có cổng (máy ảo Android), bỏ dấu "/" cuối', () {
    final ApiConfig config = ApiConfig.parse('http://10.0.2.2:5000/');
    expect(
      config.endpoint(['api', 'v1', 'search'], {'q': 'sữa'}).toString(),
      'http://10.0.2.2:5000/api/v1/search?q=s%E1%BB%AFa',
    );
  });

  test(
    'từ chối giá trị có đường dẫn, query, thông tin đăng nhập hoặc scheme lạ',
    () {
      for (final String raw in [
        'https://fluw.onrender.com/api/product',
        'https://fluw.onrender.com?x=1',
        'https://user:pass@fluw.onrender.com',
        'ftp://fluw.onrender.com',
        'fluw.onrender.com',
        '',
      ]) {
        expect(() => ApiConfig.parse(raw), throwsArgumentError, reason: raw);
      }
    },
  );
}
