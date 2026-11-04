import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/api/api_error_kind.dart';
import 'package:frontend/screens/search_results_screen.dart';
import 'package:frontend/widgets/search/search_result_tile.dart';
import 'package:frontend/widgets/search/search_results_list.dart';
import 'package:http/http.dart' as http;

import '../helpers/fake_backend.dart';
import '../helpers/test_app.dart';

Future<void> _open(
  WidgetTester tester,
  FakeBackend backend, {
  String query = 'Hảo hảo',
  Size size = phoneSize,
}) {
  return pumpScreen(
    tester,
    SearchResultsScreen(query: query),
    client: backend.client,
    size: size,
  );
}

void main() {
  testWidgets(
    'đang tải: skeleton cùng khung kết quả và dòng trạng thái; xong thì hiện danh sách',
    (tester) async {
      final Completer<http.Response> pending = Completer();
      final FakeBackend backend = FakeBackend(search: (_) => pending.future);
      await _open(tester, backend);
      await tester.pump();

      expect(find.text('Đang tìm sản phẩm'), findsOneWidget);
      expect(find.textContaining('Từ khóa “Hảo hảo”'), findsOneWidget);
      expect(find.byType(SearchResultTile), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      pending.complete(FakeBackend.fixture('search-results'));
      await settleRequest(tester);

      expect(find.text('Đang tìm sản phẩm'), findsNothing);
      expect(find.text('8 kết quả cho “Hảo hảo”'), findsOneWidget);
      expect(find.text('Mỳ Hảo Hảo'), findsOneWidget);
      expect(find.text('Acecook · Mã 8934563122201'), findsOneWidget);
      expect(find.text(SearchResultsList.approximateNote), findsNothing);
      expect(backend.requests.single.queryParameters, {'q': 'Hảo hảo'});
    },
  );

  testWidgets('thiếu tên thì ghi rõ, không đoán', (tester) async {
    final FakeBackend backend = FakeBackend(
      search: (_) => FakeBackend.json({
        'success': true,
        'query': 'sữa',
        'results': [
          {
            'barcode': '8930000000026',
            'name': null,
            'brand': null,
            'quantity': '100 g',
          },
        ],
        'total': 1,
      }, 200),
    );
    await _open(tester, backend, query: 'sữa');
    await settleRequest(tester);

    expect(find.text(SearchResultTile.missingName), findsOneWidget);
    expect(find.text('100 g · Mã 8930000000026'), findsOneWidget);
  });

  testWidgets('kết quả gần đúng thì có ghi chú', (tester) async {
    final FakeBackend backend = FakeBackend(
      search: (_) => FakeBackend.fixture('search-partial-results'),
    );
    await _open(tester, backend, query: 'mì hảo hảo');
    await settleRequest(tester);

    expect(find.text(SearchResultsList.approximateNote), findsOneWidget);
    expect(find.text('Hao Hao'), findsOneWidget);
  });

  testWidgets(
    'không có kết quả: nói rõ và gợi ý cách khác, không hiện sản phẩm bất kỳ',
    (tester) async {
      final FakeBackend backend = FakeBackend(
        search: (_) => FakeBackend.fixture('search-empty'),
      );
      await _open(tester, backend, query: 'zzqxv không tồn tại');
      await settleRequest(tester);

      expect(
        find.text('Không tìm thấy sản phẩm phù hợp với “zzqxv không tồn tại”.'),
        findsOneWidget,
      );
      expect(find.byType(SearchResultTile), findsNothing);
    },
  );

  testWidgets(
    '429: khóa nút và đếm ngược theo Retry-After, không tự gửi lại; hết giờ mới bấm được',
    (tester) async {
      int calls = 0;
      final FakeBackend backend = FakeBackend(
        search: (_) {
          calls++;
          return calls == 1
              ? FakeBackend.fixture('error-rate-limited')
              : FakeBackend.fixture('search-results');
        },
      );
      await _open(tester, backend, query: 'Vĩnh Hảo');
      await settleRequest(tester);

      expect(
        find.text('Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.'),
        findsOneWidget,
      );
      expect(find.text('Thử lại sau 60 giây'), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Thử lại sau 59 giây'), findsOneWidget);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 59));
      expect(
        calls,
        1,
        reason: 'không gửi lại khi đang khóa, cũng không tự gửi khi hết giờ',
      );

      expect(find.text('Thử lại'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await settleRequest(tester);

      expect(calls, 2);
      expect(find.text('Mỳ Hảo Hảo'), findsOneWidget);
    },
  );

  testWidgets(
    'từ khóa không hợp lệ (400): hiện thông điệp, không có nút thử lại',
    (tester) async {
      final FakeBackend backend = FakeBackend(
        search: (_) => FakeBackend.fixture('error-invalid-query'),
      );
      await _open(tester, backend, query: 'a');
      await settleRequest(tester);

      expect(
        find.text('Từ khóa tìm kiếm cần từ 2 đến 100 ký tự.'),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets('trang HTML 520: báo máy chủ tạm lỗi, cho thử lại', (
    tester,
  ) async {
    final FakeBackend backend = FakeBackend(
      search: (_) => http.Response('<html>520</html>', 520),
    );
    await _open(tester, backend);
    await settleRequest(tester);

    expect(
      find.text(ApiErrorKind.serverUnavailable.defaultMessage),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets(
    'rời màn khi đang tải thì hủy request, không còn hẹn giờ chạy ngầm',
    (tester) async {
      final FakeBackend backend = FakeBackend(
        search: (_) => Completer<http.Response>().future,
      );
      await _open(tester, backend);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  for (final Size size in [phoneSize, const Size(320, 640)]) {
    testWidgets(
      'chữ 200% không tràn khi tải và khi có kết quả (${size.width.toInt()} px)',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final Completer<http.Response> pending = Completer();
        final FakeBackend backend = FakeBackend(search: (_) => pending.future);

        await _open(tester, backend, size: size);
        await tester.pump();
        expect(tester.takeException(), isNull);

        pending.complete(FakeBackend.fixture('search-partial-results'));
        await settleRequest(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('mỗi kết quả được đọc là một nút', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FakeBackend backend = FakeBackend(
      search: (_) => FakeBackend.fixture('search-results'),
    );
    await _open(tester, backend);
    await settleRequest(tester);

    expect(
      tester.getSemantics(find.byType(SearchResultTile).first),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        label: 'Mỳ Hảo Hảo\nAcecook · Mã 8934563122201',
      ),
    );
    semantics.dispose();
  });
}
