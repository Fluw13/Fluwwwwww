import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('FluwApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FluwApp());
  });
}
