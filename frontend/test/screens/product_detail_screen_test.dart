import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/fluw_palette.dart';
import 'package:frontend/data/api/api_error_kind.dart';
import 'package:frontend/screens/product_detail_screen.dart';
import 'package:frontend/widgets/product/product_detail_skeleton.dart';
import 'package:frontend/widgets/zero_analysis_card.dart';
import 'package:http/http.dart' as http;

import '../helpers/fake_backend.dart';
import '../helpers/test_app.dart';

const String _barcode = '8930000000019';

Future<void> _open(
  WidgetTester tester,
  FakeBackend backend, {
  ThemeMode themeMode = ThemeMode.light,
}) {
  return pumpScreen(
    tester,
    const ProductDetailScreen(barcode: _barcode),
    client: backend.client,
    themeMode: themeMode,
  );
}

void main() {
  testWidgets(
    'trong lúc tải: tiêu đề trang, thanh tiến trình, skeleton và mã đang tra',
    (tester) async {
      final Completer<http.Response> pending = Completer();
      final FakeBackend backend = FakeBackend(product: (_) => pending.future);
      await _open(tester, backend);
      await tester.pump();

      expect(find.text('Chi tiết sản phẩm'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(ProductDetailSkeleton), findsOneWidget);
      expect(find.text('Đang mở chi tiết sản phẩm'), findsOneWidget);
      expect(find.textContaining('Mã $_barcode'), findsOneWidget);
      expect(
        find.text(ZeroAnalysisCard.writingText),
        findsNothing,
        reason: 'Zero không chạy cùng lúc tải sản phẩm',
      );
      expect(find.textContaining('Zero đang'), findsNothing);
      expect(backend.requests.single.path, '/api/v1/products/$_barcode');

      pending.complete(FakeBackend.fixture('product-food-complete'));
      await settleRequest(tester);
      expect(find.text('Đang mở chi tiết sản phẩm'), findsNothing);
    },
  );

  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('hiển thị sản phẩm sau khi tải xong (${mode.name})', (
      tester,
    ) async {
      final FakeBackend backend = FakeBackend(
        product: (_) => FakeBackend.fixture('product-food-complete'),
      );
      await _open(tester, backend, themeMode: mode);
      await settleRequest(tester);

      expect(find.text('Bánh quy bơ (dữ liệu thử)'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final FluwPalette expected = mode == ThemeMode.dark
          ? FluwPalette.dark
          : FluwPalette.light;
      final BuildContext context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).scaffoldBackgroundColor, expected.background);
      expect(
        tester.widget<Text>(find.text('31')).style?.color,
        expected.textPrimary,
      );
    });
  }

  testWidgets(
    'giảm chuyển động thì ẩn thanh tiến trình chạy liên tục, vẫn giữ dòng trạng thái',
    (tester) async {
      final Completer<http.Response> pending = Completer();
      final FakeBackend backend = FakeBackend(product: (_) => pending.future);
      await pumpScreen(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ProductDetailScreen(barcode: _barcode),
        ),
        client: backend.client,
      );
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Đang mở chi tiết sản phẩm'), findsOneWidget);

      pending.complete(FakeBackend.fixture('product-food-complete'));
      await tester.pump();
    },
  );

  testWidgets('lỗi → bấm thử lại → hiện lại trạng thái tải → hiện sản phẩm', (
    tester,
  ) async {
    int calls = 0;
    final Completer<http.Response> second = Completer();
    final FakeBackend backend = FakeBackend(
      product: (_) {
        calls++;
        return calls == 1
            ? FakeBackend.json({
                'success': false,
                'error': 'Mất kết nối Open Food Facts.',
                'code': 'UPSTREAM_UNAVAILABLE',
              }, 502)
            : second.future;
      },
    );

    await _open(tester, backend);
    await settleRequest(tester);
    expect(find.text('Mất kết nối Open Food Facts.'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await settleRequest(tester);
    expect(find.text('Đang mở chi tiết sản phẩm'), findsOneWidget);
    expect(find.text('Mất kết nối Open Food Facts.'), findsNothing);

    second.complete(FakeBackend.fixture('product-food-complete'));
    await settleRequest(tester);

    expect(calls, 2);
    expect(find.text('Bánh quy bơ (dữ liệu thử)'), findsOneWidget);
  });

  testWidgets('bấm "Thử lại" hai lần liên tiếp chỉ gọi lại API một lần', (
    tester,
  ) async {
    int calls = 0;
    final Completer<http.Response> retry = Completer();
    final FakeBackend backend = FakeBackend(
      product: (_) {
        calls++;
        return calls == 1
            ? http.Response('<html>502</html>', 502)
            : retry.future;
      },
    );

    await _open(tester, backend);
    await settleRequest(tester);
    expect(
      find.text(ApiErrorKind.serverUnavailable.defaultMessage),
      findsOneWidget,
    );

    await tester.tap(find.text('Thử lại'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Thử lại'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));

    expect(calls, 2);

    retry.complete(FakeBackend.fixture('product-food-complete'));
    await tester.pump();
  });

  testWidgets(
    'không tìm thấy sản phẩm: hiện thông điệp máy chủ, không có nút thử lại',
    (tester) async {
      final FakeBackend backend = FakeBackend(
        product: (_) => FakeBackend.fixture('error-product-not-found'),
      );
      await _open(tester, backend);
      await settleRequest(tester);

      expect(find.textContaining('Không tìm thấy sản phẩm'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets(
    'Open Food Facts đang giới hạn (503): khóa nút 12 giây, không tự gửi lại',
    (tester) async {
      int calls = 0;
      final FakeBackend backend = FakeBackend(
        product: (_) {
          calls++;
          return FakeBackend.fixture('error-upstream-rate-limited');
        },
      );
      await _open(tester, backend);
      await settleRequest(tester);

      expect(find.text('Thử lại sau 12 giây'), findsOneWidget);
      await tester.pump(const Duration(seconds: 12));
      expect(find.text('Thử lại'), findsOneWidget);
      expect(calls, 1);
    },
  );

  testWidgets(
    'rời màn khi đang tải thì hủy request, không còn hẹn giờ chạy ngầm',
    (tester) async {
      final FakeBackend backend = FakeBackend(
        product: (_) => Completer<http.Response>().future,
      );
      await _open(tester, backend);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Zero tải riêng: chỉ gọi /analysis khi bấm "Hỏi Zero", sau khi sản phẩm đã hiện',
    (tester) async {
      final FakeBackend backend = FakeBackend(
        product: (_) => FakeBackend.fixture('product-food-complete'),
        analysis: (_) => FakeBackend.fixture('analysis-ok'),
      );
      await _open(tester, backend);
      await settleRequest(tester);

      expect(backend.paths, ['/api/v1/products/$_barcode']);

      await tester.scrollUntilVisible(
        find.text(ZeroAnalysisCard.askLabel),
        300,
      );
      await tester.tap(find.text(ZeroAnalysisCard.askLabel));
      await settleRequest(tester);

      expect(backend.paths, [
        '/api/v1/products/$_barcode',
        '/api/v1/products/$_barcode/analysis',
      ]);
      expect(find.text('Điểm chính'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('31'), -300);
      expect(
        find.text('31'),
        findsOneWidget,
        reason: 'điểm vẫn lấy từ score, không đổi theo AI',
      );
    },
  );

  testWidgets('Zero lỗi không ảnh hưởng sản phẩm và điểm', (tester) async {
    final FakeBackend backend = FakeBackend(
      product: (_) => FakeBackend.fixture('product-food-complete'),
      analysis: (_) => http.Response('<html>502</html>', 502),
    );
    await _open(tester, backend);
    await settleRequest(tester);
    await tester.scrollUntilVisible(find.text(ZeroAnalysisCard.askLabel), 300);
    await tester.tap(find.text(ZeroAnalysisCard.askLabel));
    await settleRequest(tester);

    expect(
      find.text(ApiErrorKind.serverUnavailable.defaultMessage),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('31'), -300);
    expect(find.text('Bánh quy bơ (dữ liệu thử)'), findsOneWidget);
  });

  testWidgets(
    'rời màn khi Zero đang viết thì hủy request, không còn hẹn giờ chạy ngầm',
    (tester) async {
      final FakeBackend backend = FakeBackend(
        product: (_) => FakeBackend.fixture('product-food-complete'),
        analysis: (_) => Completer<http.Response>().future,
      );
      await _open(tester, backend);
      await settleRequest(tester);
      await tester.scrollUntilVisible(
        find.text(ZeroAnalysisCard.askLabel),
        300,
      );
      await tester.tap(find.text(ZeroAnalysisCard.askLabel));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
