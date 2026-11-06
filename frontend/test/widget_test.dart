import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/home_screen.dart';

import 'helpers/fake_backend.dart';
import 'helpers/fluw_app_harness.dart';

void main() {
  testWidgets(
    'HomeScreen hiển thị màn hình chính và đánh thức máy chủ một lần',
    (tester) async {
      final FakeBackend backend = FakeBackend();
      await pumpFluwApp(tester, const HomeScreen(), client: backend.client);
      await tester.pump();

      expect(find.text('Bạn đang ăn món gì?'), findsOneWidget);
      expect(find.text('Quét mã vạch'), findsOneWidget);
      expect(backend.paths, ['/health']);
      expect(backend.client.isServerAwake, isTrue);
    },
  );
}
