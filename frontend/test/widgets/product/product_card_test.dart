import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/product_summary.dart';
import 'package:frontend/widgets/product/product_card.dart';
import 'package:frontend/widgets/product/score_pill.dart';

import '../../helpers/product_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('thẻ sản phẩm hiện tên, thương hiệu, calo và điểm kèm chữ', (tester) async {
    int taps = 0;
    await pumpOnPhone(tester, ProductCard(product: ProductSummary.fromProduct(buildProduct()), onTap: () => taps++));

    expect(find.text('Bánh quy yến mạch'), findsOneWidget);
    expect(find.text('Thương hiệu mẫu · 412 kcal'), findsOneWidget);
    expect(find.text('7,8 · Cao'), findsOneWidget);

    await tester.tap(find.byType(ProductCard));
    expect(taps, 1);
  });

  testWidgets('chưa có điểm thì ghi "Chưa chấm"; thiếu calo hoặc thương hiệu thì không thừa dấu "·"', (tester) async {
    await pumpOnPhone(
      tester,
      Column(
        children: [
          ProductCard(product: ProductSummary.fromProduct(buildProduct(score: null, calories: null)), onTap: () {}),
          ProductCard(product: ProductSummary.fromProduct(buildProduct(brand: '', calories: 95)), onTap: () {}),
        ],
      ),
      themeMode: ThemeMode.dark,
    );

    expect(find.text('Chưa chấm'), findsOneWidget);
    expect(find.text('Thương hiệu mẫu'), findsOneWidget);
    expect(find.text('95 kcal'), findsOneWidget);
  });

  testWidgets('trình đọc màn hình đọc cả thẻ là một nút', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpOnPhone(tester, ProductCard(product: ProductSummary.fromProduct(buildProduct()), onTap: () {}));

    expect(
      tester.getSemantics(find.byType(ProductCard)),
      matchesSemantics(
        label: 'Bánh quy yến mạch\nThương hiệu mẫu · 412 kcal\nĐiểm 7,8 trên 10, Cao',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  for (final double scale in [1.0, 2.0]) {
    testWidgets('tên dài, màn 320 px, chữ ${scale}x: không tràn', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpOnPhone(
        tester,
        ProductCard(
          product: ProductSummary.fromProduct(
            buildProduct(name: 'Sữa chua uống lên men tự nhiên vị dâu tây hộp 6 chai', score: 10),
          ),
          onTap: () {},
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ScorePill), findsOneWidget);
    });
  }
}
