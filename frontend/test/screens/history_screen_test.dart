import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/history/history_kind.dart';
import 'package:frontend/core/history/session_history.dart';
import 'package:frontend/models/product_summary.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/product_detail_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/product/product_card.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/api_fixtures.dart';
import '../helpers/fluw_app_harness.dart';

class _DisposeTrackingApi extends ApiService {
  _DisposeTrackingApi() : super(client: MockClient((_) async => jsonResponse(productBody(), 200)));

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

ApiService _api() {
  return ApiService(
    client: MockClient(
      (_) async => http.Response(
        '{"success":false,"error":"Không tìm thấy"}',
        404,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
}

void main() {
  testWidgets('chưa có gì thì hiện trạng thái rỗng, không có nút Xóa', (tester) async {
    await pumpFluwApp(tester, HistoryScreen(kind: HistoryKind.scans, apiService: _api()));

    expect(find.text('Chưa quét sản phẩm nào'), findsOneWidget);
    expect(find.text(HistoryScreen.sessionNote), findsOneWidget);
    expect(find.text('Xóa'), findsNothing);
  });

  testWidgets('lịch sử quét: mỗi sản phẩm một thẻ, bấm vào mở chi tiết theo mã vạch', (tester) async {
    final List<Uri> requests = [];
    final ApiService api = ApiService(
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response('{"success":false,"error":"x"}', 404);
      }),
    );
    final SessionHistory history = SessionHistory()
      ..addScan(const ProductSummary(barcode: '8934563138165', name: 'Mì Hảo Hảo', brand: '', imageUrl: ''))
      ..addScan(const ProductSummary(barcode: '', name: 'Bánh mì', brand: '', imageUrl: ''));
    await pumpFluwApp(tester, HistoryScreen(kind: HistoryKind.scans, apiService: api), history: history);

    expect(find.byType(ProductCard), findsNWidgets(2));

    await tester.tap(find.text('Mì Hảo Hảo'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(requests.single.path, endsWith('/8934563138165'));
  });

  testWidgets('lịch sử tìm kiếm: bấm lại từ khóa thì đưa lên đầu và tìm lại', (tester) async {
    final SessionHistory history = SessionHistory()
      ..addSearch('mì')
      ..addSearch('sữa');
    await pumpFluwApp(tester, HistoryScreen(kind: HistoryKind.searches, apiService: _api()), history: history);

    await tester.tap(find.text('mì'));
    await tester.pumpAndSettle();

    expect(history.searches, ['mì', 'sữa']);
    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });

  testWidgets('Xóa cần xác nhận; Hủy thì giữ nguyên, Xóa thì làm trống', (tester) async {
    final SessionHistory history = SessionHistory()..addSearch('mì');
    await pumpFluwApp(tester, HistoryScreen(kind: HistoryKind.searches, apiService: _api()), history: history);

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

  testWidgets('mở lại từ lịch sử quét và tải được: sản phẩm lên đầu lịch sử', (tester) async {
    final RecordingApi api = RecordingApi();
    final SessionHistory history = SessionHistory()
      ..addScan(const ProductSummary(barcode: sampleBarcode, name: 'Sữa chua', brand: '', imageUrl: ''))
      ..addScan(const ProductSummary(barcode: '2', name: 'Mới hơn', brand: '', imageUrl: ''));
    await pumpFluwApp(tester, HistoryScreen(kind: HistoryKind.scans, apiService: api.service), history: history);

    await tester.tap(find.text('Sữa chua'));
    await tester.pumpAndSettle();

    expect(history.scans.map((product) => product.barcode), [sampleBarcode, '2']);
  });

  testWidgets('tìm lại từ lịch sử tìm kiếm và tải được: không ghi vào lịch sử quét', (tester) async {
    final RecordingApi api = RecordingApi();
    final SessionHistory history = SessionHistory()..addSearch('sữa chua');
    await pumpFluwApp(tester, HistoryScreen(kind: HistoryKind.searches, apiService: api.service), history: history);

    await tester.tap(find.text('sữa chua'));
    await tester.pumpAndSettle();

    expect(api.productRequests, hasLength(1));
    expect(history.scans, isEmpty);
  });

  for (final HistoryKind kind in HistoryKind.values) {
    testWidgets('${kind.title}: màn 320 px, chữ 200% không tràn', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final SessionHistory history = SessionHistory()
        ..addSearch('một từ khóa tìm kiếm rất dài để thử xuống dòng')
        ..addScan(
          const ProductSummary(
            barcode: '1',
            name: 'Bánh quy yến mạch nguyên hạt vị mật ong hộp lớn',
            brand: 'Hãng',
            imageUrl: '',
            score: 10,
          ),
        );
      await pumpFluwApp(tester, HistoryScreen(kind: kind, apiService: _api()), history: history);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ApiService được truyền vào không bị màn Chi tiết dispose khi quay lại', (tester) async {
    final _DisposeTrackingApi api = _DisposeTrackingApi();
    final SessionHistory history = SessionHistory()..addSearch('sữa chua');
    await pumpFluwApp(tester, HistoryScreen(kind: HistoryKind.searches, apiService: api), history: history);

    await tester.tap(find.text('sữa chua'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsNothing);
    expect(api.disposed, isFalse);
  });
}
