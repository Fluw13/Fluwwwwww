import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('FluwApp hiển thị màn hình chính', (WidgetTester tester) async {
    await tester.pumpWidget(const FluwApp());

    expect(find.text('Bạn đang ăn món gì?'), findsOneWidget);
    expect(find.text('QUÉT MÃ VẠCH'), findsOneWidget);
  });
}
