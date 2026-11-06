import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/product_summary.dart';
import 'package:frontend/widgets/product/product_card.dart';
import 'package:frontend/widgets/product/score_pill.dart';

import '../../helpers/product_fixtures.dart';
import '../../helpers/test_app.dart';

ProductSummary _summary(
  String fixture, {
  void Function(Map<String, dynamic> product, Map<String, dynamic> score)? edit,
}) {
  return ProductSummary.fromDetails(productDetails(fixture, edit: edit));
}

void main() {
  testWidgets(
    'thẻ sản phẩm dựng từ dữ liệu v1: tên, thương hiệu, calo, điểm kèm nhãn backend gửi',
    (tester) async {
      int taps = 0;
      await pumpOnPhone(
        tester,
        ProductCard(
          product: _summary('product-food-complete'),
          onTap: () => taps++,
        ),
      );

      expect(find.text('Bánh quy bơ (dữ liệu thử)'), findsOneWidget);
      expect(find.text('Fluw Test · 478 kcal'), findsOneWidget);
      expect(find.text('31 · Nên hạn chế'), findsOneWidget);
      expect(find.text('Kém'), findsNothing);

      await tester.tap(find.byType(ProductCard));
      expect(taps, 1);
    },
  );

  testWidgets('nhãn lấy nguyên từ backend, không tự áp ngưỡng điểm', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      ProductCard(
        product: _summary(
          'product-yogurt-good',
          edit: (_, score) => (score['total'] as Map<String, dynamic>)
            ..['value'] = 12
            ..['label'] = 'Nhãn từ máy chủ',
        ),
        onTap: () {},
      ),
    );

    expect(find.text('12 · Nhãn từ máy chủ'), findsOneWidget);
  });

  testWidgets(
    'chưa đủ dữ liệu thì ghi "Chưa đủ dữ liệu", không hiện số; thiếu tên/calo/thương hiệu không thừa "·"',
    (tester) async {
      await pumpOnPhone(
        tester,
        Column(
          children: [
            ProductCard(
              product: _summary('product-needs-prepared-data'),
              onTap: () {},
            ),
            ProductCard(
              product: _summary(
                'product-water',
                edit: (product, _) => product
                  ..['name'] = null
                  ..['brand'] = null,
              ),
              onTap: () {},
            ),
          ],
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text(ScorePill.notEnoughData), findsOneWidget);
      expect(find.text(ProductCard.missingName), findsOneWidget);
      expect(find.text('Fluw Test · 450 kcal'), findsOneWidget);
    },
  );

  testWidgets('trình đọc màn hình đọc cả thẻ là một nút', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpOnPhone(
      tester,
      ProductCard(product: _summary('product-food-complete'), onTap: () {}),
    );

    expect(
      tester.getSemantics(find.byType(ProductCard)),
      matchesSemantics(
        label: 'Bánh quy bơ (dữ liệu thử)\nFluw Test · 478 kcal\nĐiểm 31 trên 100, mức Nên hạn chế',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  for (final double scale in [1.0, 2.0]) {
    testWidgets('tên dài, màn 320 px, chữ ${scale}x: không tràn', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpOnPhone(
        tester,
        ProductCard(
          product: _summary(
            'product-water',
            edit: (product, _) => product['name'] =
                'Sữa chua uống lên men tự nhiên vị dâu tây hộp 6 chai',
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
