import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/history/history_scope.dart';
import 'package:frontend/core/history/session_history.dart';
import 'package:frontend/core/navigation/product_origin.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/fluw_palette.dart';
import 'package:frontend/screens/product_detail_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/api_fixtures.dart';

Future<void> _pumpScreen(
  WidgetTester tester,
  ApiService apiService, {
  ThemeMode themeMode = ThemeMode.light,
  String query = sampleBarcode,
  ProductOrigin origin = ProductOrigin.search,
  SessionHistory? history,
}) {
  return tester.pumpWidget(
    HistoryScope(
      history: history ?? SessionHistory(),
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: ProductDetailScreen(query: query, origin: origin, apiService: apiService),
      ),
    ),
  );
}

void main() {
  testWidgets('trong lúc tải hiện tiêu đề trang, thanh tiến trình và mã đang tra', (tester) async {
    final Completer<http.Response> pending = Completer();
    await _pumpScreen(tester, ApiService(client: MockClient((_) => pending.future)));
    await tester.pump();

    expect(find.text('Chi tiết sản phẩm'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Đang mở chi tiết sản phẩm'), findsOneWidget);
    expect(find.textContaining('Mã $sampleBarcode'), findsOneWidget);

    pending.complete(jsonResponse(productBody(), 200));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('tìm theo tên thì ghi là từ khóa, không gọi là mã', (tester) async {
    final Completer<http.Response> pending = Completer();
    await _pumpScreen(tester, ApiService(client: MockClient((_) => pending.future)), query: 'mì hảo hảo');
    await tester.pump();

    expect(find.textContaining('Từ khóa “mì hảo hảo”'), findsOneWidget);

    pending.complete(jsonResponse(productBody(), 200));
    await tester.pump(const Duration(milliseconds: 300));
  });

  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('hiển thị sản phẩm sau khi tải xong (${mode.name})', (tester) async {
      await _pumpScreen(
        tester,
        ApiService(client: MockClient((_) async => jsonResponse(productBody(), 200))),
        themeMode: mode,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sữa chua'), findsOneWidget);
      expect(find.text('6,7'), findsOneWidget);
      expect(find.text('Đang mở chi tiết sản phẩm'), findsNothing);
      expect(tester.takeException(), isNull);

      final FluwPalette expected = mode == ThemeMode.dark ? FluwPalette.dark : FluwPalette.light;
      final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final BuildContext context = tester.element(find.byType(Scaffold));
      expect(scaffold.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor, expected.background);
      expect(tester.widget<Text>(find.text('6,7')).style?.color, expected.textPrimary);
    });
  }

  testWidgets('giảm chuyển động thì ẩn thanh tiến trình chạy liên tục, vẫn giữ dòng trạng thái', (tester) async {
    final Completer<http.Response> pending = Completer();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ProductDetailScreen(
            query: sampleBarcode,
            origin: ProductOrigin.search,
            apiService: ApiService(client: MockClient((_) => pending.future)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Đang mở chi tiết sản phẩm'), findsOneWidget);

    pending.complete(jsonResponse(productBody(), 200));
    await tester.pump();
  });

  testWidgets('lỗi → bấm thử lại → hiện lại trạng thái tải → hiện sản phẩm', (tester) async {
    int calls = 0;
    final Completer<http.Response> second = Completer();
    final ApiService apiService = ApiService(
      client: MockClient((_) async {
        calls++;
        if (calls == 1) {
          return jsonResponse(jsonEncode({'success': false, 'error': 'Không tìm thấy sản phẩm.'}), 404);
        }
        return second.future;
      }),
    );

    await _pumpScreen(tester, apiService);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Không tìm thấy sản phẩm.'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Đang mở chi tiết sản phẩm'), findsOneWidget);
    expect(find.text('Không tìm thấy sản phẩm.'), findsNothing);

    second.complete(jsonResponse(productBody(), 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(calls, 2);
    expect(find.text('Sữa chua'), findsOneWidget);
  });

  testWidgets('bấm "Thử lại" hai lần liên tiếp chỉ gọi lại API một lần', (tester) async {
    int calls = 0;
    final Completer<http.Response> retry = Completer();
    final ApiService apiService = ApiService(
      client: MockClient((_) async {
        calls++;
        if (calls == 1) {
          return jsonResponse(jsonEncode({'success': false, 'error': 'Mất kết nối.'}), 503);
        }
        return retry.future;
      }),
    );

    await _pumpScreen(tester, apiService);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Thử lại'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Thử lại'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));

    expect(calls, 2);

    retry.complete(jsonResponse(productBody(), 200));
    await tester.pump();
  });

  group('lịch sử quét trong phiên', () {
    testWidgets('mở từ màn quét và tải được thì thêm vào lịch sử quét', (tester) async {
      final SessionHistory history = SessionHistory();
      await _pumpScreen(
        tester,
        ApiService(client: MockClient((_) async => jsonResponse(productBody(), 200))),
        origin: ProductOrigin.scan,
        history: history,
      );
      await tester.pumpAndSettle();

      expect(history.scans.map((product) => product.barcode), [sampleBarcode]);
      expect(history.scans.single.score, 6.7);
    });

    testWidgets('mở từ ô tìm kiếm thì không thêm vào lịch sử quét', (tester) async {
      final SessionHistory history = SessionHistory();
      await _pumpScreen(
        tester,
        ApiService(client: MockClient((_) async => jsonResponse(productBody(), 200))),
        history: history,
      );
      await tester.pumpAndSettle();

      expect(history.scans, isEmpty);
    });

    testWidgets('tải lỗi thì không thêm gì vào lịch sử', (tester) async {
      final SessionHistory history = SessionHistory();
      await _pumpScreen(
        tester,
        ApiService(client: MockClient((_) async => jsonResponse('{"success":false,"error":"Không tìm thấy"}', 404))),
        origin: ProductOrigin.scan,
        history: history,
      );
      await tester.pumpAndSettle();

      expect(history.scans, isEmpty);
    });
  });
}
