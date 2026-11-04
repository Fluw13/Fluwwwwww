import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/api/api_cancel_token.dart';
import 'package:frontend/data/api/http_date.dart';
import 'package:frontend/data/api/retry_after.dart';

void main() {
  final DateTime now = DateTime.utc(1994, 11, 6, 8, 49, 0);

  group('parseHttpDate', () {
    test('đọc cả 3 định dạng của RFC 9110', () {
      final DateTime expected = DateTime.utc(1994, 11, 6, 8, 49, 37);
      expect(parseHttpDate('Sun, 06 Nov 1994 08:49:37 GMT'), expected);
      expect(parseHttpDate('Sunday, 06-Nov-94 08:49:37 GMT'), expected);
      expect(parseHttpDate('Sun Nov  6 08:49:37 1994'), expected);
    });

    test('từ chối ngày không tồn tại và chuỗi lạ', () {
      expect(parseHttpDate('Mon, 31 Feb 2026 10:00:00 GMT'), isNull);
      expect(parseHttpDate('Mon, 01 Foo 2026 10:00:00 GMT'), isNull);
      expect(parseHttpDate('2026-11-04T10:00:00Z'), isNull);
    });
  });

  group('parseRetryAfter', () {
    test('số giây', () {
      expect(parseRetryAfter('60', now: now), const Duration(seconds: 60));
      expect(parseRetryAfter(' 0 ', now: now), Duration.zero);
    });

    test('ngày giờ HTTP tính từ thời điểm hiện tại', () {
      expect(
        parseRetryAfter('Sun, 06 Nov 1994 08:49:37 GMT', now: now),
        const Duration(seconds: 37),
      );
    });

    test('thiếu, hỏng hoặc số âm thì không có thời gian chờ', () {
      expect(parseRetryAfter(null, now: now), isNull);
      expect(parseRetryAfter('', now: now), isNull);
      expect(parseRetryAfter('-5', now: now), isNull);
      expect(parseRetryAfter('1.5', now: now), isNull);
    });

    test('quá dài thì giới hạn ở 10 phút', () {
      expect(parseRetryAfter('86400', now: now), maxRetryAfter);
      expect(parseRetryAfter('9' * 40, now: now), maxRetryAfter);
    });
  });

  group('ApiCancelToken', () {
    test('gọi listener một lần khi hủy; listener đã gỡ thì không gọi', () {
      final ApiCancelToken token = ApiCancelToken();
      int kept = 0;
      int removed = 0;
      token.onCancel(() => kept++);
      token.onCancel(() => removed++)();

      token
        ..cancel()
        ..cancel();

      expect(kept, 1);
      expect(removed, 0);
      expect(token.isCancelled, isTrue);
    });

    test('đăng ký sau khi đã hủy thì được gọi ngay', () {
      final ApiCancelToken token = ApiCancelToken()..cancel();
      int calls = 0;
      token.onCancel(() => calls++);
      expect(calls, 1);
    });
  });
}
