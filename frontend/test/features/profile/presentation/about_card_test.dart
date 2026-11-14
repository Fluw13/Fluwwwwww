import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/presentation/about_card.dart';

void main() {
  testWidgets('thẻ Về Fluw ghi nguồn dữ liệu và mở được trang giấy phép', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AboutCard())));

    expect(find.textContaining('Open Food Facts (ODbL)'), findsOneWidget);
    expect(find.textContaining('USDA FoodData Central (CC0)'), findsOneWidget);

    await tester.tap(find.text('Nguồn dữ liệu và giấy phép'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
