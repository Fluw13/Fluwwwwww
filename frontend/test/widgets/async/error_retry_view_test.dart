import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/async/error_retry_view.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets(
    'màn ngang thấp + chữ 200% vẫn cuộn được, không tràn, nút thử lại bấm được',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      int retries = 0;

      await pumpOnPhone(
        tester,
        ErrorRetryView(
          message: 'Máy chủ phản hồi quá lâu. Vui lòng kiểm tra kết nối mạng rồi thử lại sau ít phút.',
          onRetry: () => retries++,
        ),
        size: const Size(640, 320),
      );
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Thử lại'), 100);
      await tester.tap(find.text('Thử lại'));
      expect(retries, 1);
    },
  );

  testWidgets('thông báo lỗi được trình đọc màn hình đọc ngay', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpOnPhone(
      tester,
      ErrorRetryView(message: 'Không tìm thấy sản phẩm.', onRetry: () {}),
    );

    expect(
      tester.getSemantics(find.text('Không tìm thấy sản phẩm.')),
      matchesSemantics(label: 'Không tìm thấy sản phẩm.', isLiveRegion: true),
    );
    semantics.dispose();
  });

  testWidgets(
    'có Retry-After: nút bị khóa và đếm ngược, hết giờ mới bấm được',
    (tester) async {
      int retries = 0;
      await pumpOnPhone(
        tester,
        ErrorRetryView(
          message: 'Chờ chút.',
          onRetry: () => retries++,
          retryAfter: const Duration(milliseconds: 2500),
        ),
      );

      expect(find.text('Thử lại sau 3 giây'), findsOneWidget);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(retries, 0);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Thử lại sau 1 giây'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Thử lại'));
      expect(retries, 1);
    },
  );

  testWidgets('không có onRetry thì không có nút', (tester) async {
    await pumpOnPhone(
      tester,
      const ErrorRetryView(message: 'Không tìm thấy sản phẩm.', onRetry: null),
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Không tìm thấy sản phẩm.'), findsOneWidget);
  });
}
