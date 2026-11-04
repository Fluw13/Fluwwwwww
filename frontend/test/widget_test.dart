import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/search/search_input.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/search_results_screen.dart';

import 'helpers/fake_backend.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets(
    'HomeScreen hiển thị màn hình chính và đánh thức máy chủ một lần',
    (tester) async {
      final FakeBackend backend = FakeBackend();
      await pumpScreen(tester, const HomeScreen(), client: backend.client);
      await tester.pump();

      expect(find.text('Bạn đang ăn món gì?'), findsOneWidget);
      expect(find.text('QUÉT MÃ VẠCH'), findsOneWidget);
      expect(backend.paths, ['/health']);
      expect(backend.client.isServerAwake, isTrue);
    },
  );

  testWidgets(
    'gõ chữ không gửi request; bấm tìm mới mở màn kết quả và tìm đúng một lần',
    (tester) async {
      final FakeBackend backend = FakeBackend(
        search: (_) => FakeBackend.fixture('search-results'),
      );
      await pumpScreen(tester, const HomeScreen(), client: backend.client);
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'H');
      await tester.enterText(find.byType(TextField), 'Hảo');
      await tester.enterText(find.byType(TextField), 'Hảo hảo');
      await tester.pump();
      expect(backend.countPath((path) => path.contains('search')), 0);

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byType(SearchResultsScreen), findsOneWidget);
      expect(find.text('Mỳ Hảo Hảo'), findsOneWidget);
      expect(backend.countPath((path) => path.contains('search')), 1);
      expect(backend.requests.last.queryParameters['q'], 'Hảo hảo');
    },
  );

  testWidgets('từ khóa 1 ký tự: báo ngay dưới ô nhập, không gửi request', (
    tester,
  ) async {
    final FakeBackend backend = FakeBackend();
    await pumpScreen(tester, const HomeScreen(), client: backend.client);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.byTooltip('Tìm'));
    await tester.pumpAndSettle();

    expect(find.text(SearchInput.tooShortMessage), findsOneWidget);
    expect(find.byType(SearchResultsScreen), findsNothing);
    expect(backend.paths, ['/health']);
  });
}
