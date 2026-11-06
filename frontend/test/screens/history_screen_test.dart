import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/history/history_kind.dart';
import 'package:frontend/core/history/session_history.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/product_detail_screen.dart';
import 'package:frontend/screens/search_results_screen.dart';
import 'package:frontend/widgets/product/product_card.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fake_backend.dart';
import '../helpers/fluw_app_harness.dart';

Future<FakeBackend> _pump(
  WidgetTester tester,
  HistoryKind kind, {
  SessionHistory? history,
}) async {
  final FakeBackend backend = productBackend();
  await pumpFluwApp(
    tester,
    HistoryScreen(kind: kind),
    history: history,
    client: backend.client,
  );
  return backend;
}

void main() {
  testWidgets('chưa có gì thì hiện trạng thái rỗng, không có nút Xóa', (
    tester,
  ) async {
    await _pump(tester, HistoryKind.scans);

    expect(find.text('Chưa quét sản phẩm nào'), findsOneWidget);
    expect(find.text(HistoryScreen.sessionNote), findsOneWidget);
    expect(find.text('Xóa'), findsNothing);
  });

  testWidgets(
    'lịch sử quét: mỗi sản phẩm một thẻ, bấm vào mở chi tiết v1 theo mã vạch',
    (tester) async {
      final SessionHistory history = SessionHistory()
        ..addScan(sampleSummary(name: 'Sữa chua'))
        ..addScan(
          sampleSummary(
            barcode: '8930000000026',
            name: 'Mì Hảo Hảo',
            score: null,
            levelLabel: null,
          ),
        );
      final FakeBackend backend = await _pump(
        tester,
        HistoryKind.scans,
        history: history,
      );

      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(
        find.text('Chưa đủ dữ liệu'),
        findsOneWidget,
        reason: 'điểm null không hiện số',
      );

      await tester.tap(find.text('Sữa chua'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(
        backend.productRequests.single.path,
        '/api/v1/products/$sampleBarcode',
      );
    },
  );

  testWidgets(
    'lịch sử tìm kiếm: bấm lại từ khóa thì đưa lên đầu và mở màn kết quả',
    (tester) async {
      final SessionHistory history = SessionHistory()
        ..addSearch('mì')
        ..addSearch('sữa');
      final FakeBackend backend = await _pump(
        tester,
        HistoryKind.searches,
        history: history,
      );

      await tester.tap(find.text('mì'));
      await tester.pumpAndSettle();

      expect(history.searches, ['mì', 'sữa']);
      expect(find.byType(SearchResultsScreen), findsOneWidget);
      expect(backend.searchRequests.single.queryParameters['q'], 'mì');
    },
  );

  testWidgets(
    'từ khóa là mã vạch thì mở thẳng chi tiết, không ghi vào lịch sử quét',
    (tester) async {
      final SessionHistory history = SessionHistory()..addSearch(sampleBarcode);
      final FakeBackend backend = await _pump(
        tester,
        HistoryKind.searches,
        history: history,
      );

      await tester.tap(find.text(sampleBarcode));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(backend.productRequests, hasLength(1));
      expect(history.scans, isEmpty);
    },
  );

  testWidgets('Xóa cần xác nhận; Hủy thì giữ nguyên, Xóa thì làm trống', (
    tester,
  ) async {
    final SessionHistory history = SessionHistory()..addSearch('mì');
    await _pump(tester, HistoryKind.searches, history: history);

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(history.searches, ['mì']);

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Xóa').last);
    await tester.pumpAndSettle();

    expect(history.searches, isEmpty);
    expect(find.text('Chưa tìm kiếm gì'), findsOneWidget);
  });

  testWidgets('mở lại từ lịch sử quét và tải được: sản phẩm lên đầu lịch sử', (
    tester,
  ) async {
    final SessionHistory history = SessionHistory()
      ..addScan(sampleSummary(name: 'Sữa chua'))
      ..addScan(sampleSummary(barcode: '2', name: 'Mới hơn'));
    await _pump(tester, HistoryKind.scans, history: history);

    await tester.tap(find.text('Sữa chua'));
    await tester.pumpAndSettle();

    expect(history.scans.map((product) => product.barcode), [
      sampleBarcode,
      '2',
    ]);
  });

  for (final HistoryKind kind in HistoryKind.values) {
    testWidgets('${kind.title}: màn 320 px, chữ 200% không tràn', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final SessionHistory history = SessionHistory()
        ..addSearch('một từ khóa tìm kiếm rất dài để thử xuống dòng')
        ..addScan(
          sampleSummary(
            barcode: '1',
            name: 'Bánh quy yến mạch nguyên hạt vị mật ong hộp lớn',
            score: 100,
          ),
        );
      await _pump(tester, kind, history: history);

      expect(tester.takeException(), isNull);
    });
  }
}
