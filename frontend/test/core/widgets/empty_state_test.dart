import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/widgets/empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('hiện icon, tiêu đề và lời nhắn', (tester) async {
    await tester.pumpWidget(
      _wrap(const EmptyState(icon: Icons.search, title: 'Chưa có kết quả', message: 'Thử từ khóa khác.')),
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('Chưa có kết quả'), findsOneWidget);
    expect(find.text('Thử từ khóa khác.'), findsOneWidget);
  });

  testWidgets('không có lời nhắn thì chỉ hiện tiêu đề', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyState(icon: Icons.search, title: 'Chưa có kết quả')));

    expect(find.byType(Text), findsOneWidget);
  });
}
