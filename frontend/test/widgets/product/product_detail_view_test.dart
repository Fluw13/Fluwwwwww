import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/product_image_screen.dart';
import 'package:frontend/screens/score_explanation_screen.dart';
import 'package:frontend/widgets/circular_score_ring.dart';
import 'package:frontend/widgets/product/additives_section.dart';
import 'package:frontend/widgets/product/data_source_footer.dart';
import 'package:frontend/widgets/product/product_detail_view.dart';
import 'package:frontend/widgets/product/product_header.dart';
import 'package:frontend/widgets/product/product_thumbnail.dart';
import 'package:frontend/widgets/product/score_summary_card.dart';

import '../../helpers/product_fixtures.dart';
import '../../helpers/test_app.dart';

Future<void> _show(
  WidgetTester tester,
  String fixture, {
  Size size = phoneSize,
  ThemeMode mode = ThemeMode.light,
}) {
  return pumpOnPhone(
    tester,
    ProductDetailView(details: productDetails(fixture)),
    size: size,
    themeMode: mode,
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 300);

/// URLs of every network image on screen; `cacheWidth` wraps the provider in
/// a [ResizeImage].
List<String> _networkUrls(WidgetTester tester) {
  return [
    for (final Image image in tester.widgetList<Image>(find.byType(Image)))
      switch (image.image) {
        ResizeImage(imageProvider: final NetworkImage network) => network.url,
        final NetworkImage network => network.url,
        _ => '',
      },
  ];
}

void main() {
  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'đủ dữ liệu: điểm từ backend, sản phẩm, dinh dưỡng và mọi mục (${mode.name})',
      (tester) async {
        await _show(tester, 'product-food-complete', mode: mode);

        expect(find.byType(CircularScoreRing), findsOneWidget);
        expect(find.text('31'), findsOneWidget);
        expect(find.text('Nên hạn chế'), findsOneWidget);
        expect(find.text('Dinh dưỡng 18/100 · trọng số 70%'), findsOneWidget);
        expect(find.text('Phụ gia 60/100 · trọng số 30%'), findsOneWidget);
        expect(find.text('18 × 0,7 + 60 × 0,3 = 30,6 → 31'), findsOneWidget);
        expect(find.text('Công thức fluw-score-1.0'), findsOneWidget);
        expect(find.text('Bánh quy bơ (dữ liệu thử)'), findsOneWidget);
        expect(find.text('Fluw Test · 120 g · 8930000000019'), findsOneWidget);

        await _scrollTo(tester, find.text('Dinh dưỡng trên 100 g'));
        expect(find.bySemanticsLabel('Chất đạm: 6 gam'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Năng lượng: 478 kilocalo'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Năng lượng (kJ): 2.000 kilojun'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Muối: 0,5 gam'), findsOneWidget);

        await _scrollTo(tester, find.textContaining('Bột mì, đường, bơ'));
        await _scrollTo(tester, find.text('đậu nành'));
        expect(find.text('gluten'), findsOneWidget);
        await _scrollTo(tester, find.text('trứng'));
        await _scrollTo(tester, find.text('Mono- và diglycerid của axit béo'));
        expect(find.text('Phụ gia (4)'), findsOneWidget);
        expect(find.text('E471'), findsOneWidget);
        await _scrollTo(tester, find.text('Công ty Thử nghiệm Fluw'));
        await _scrollTo(tester, find.text('Việt Nam'));
        await _scrollTo(tester, find.text('Ảnh sản phẩm'));
        await _scrollTo(
          tester,
          find.text('Dữ liệu: Open Food Facts · ODbL · ảnh CC BY-SA'),
        );
        expect(
          find.text('Cập nhật trên Open Food Facts: 30/10/2025'),
          findsOneWidget,
        );

        expect(find.text('Kém'), findsNothing);
        expect(find.text('Do AI tạo'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('cùng một khung cho sản phẩm khác: chỉ dữ liệu thay đổi', (
    tester,
  ) async {
    await _show(tester, 'product-yogurt-good');

    expect(find.text('85'), findsOneWidget);
    expect(find.text('Tốt'), findsOneWidget);
    expect(find.text('79 × 0,7 + 100 × 0,3 = 85,3 → 85'), findsOneWidget);
  });

  testWidgets('nhãn mức lấy nguyên từ backend, app không tự áp ngưỡng điểm', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      ProductDetailView(
        details: productDetails(
          'product-yogurt-good',
          edit: (product, score) => (score['total'] as Map<String, dynamic>)
            ..['value'] = 12
            ..['label'] = 'Nhãn thử từ máy chủ',
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Nhãn thử từ máy chủ'), findsOneWidget);
    expect(find.text('Nên hạn chế'), findsNothing);
  });

  testWidgets(
    'thiếu dữ liệu: không vẽ vòng điểm, nói rõ, liệt kê mục thiếu, ghi điểm thành phần',
    (tester) async {
      await _show(tester, 'product-needs-prepared-data');

      expect(find.byType(CircularScoreRing), findsNothing);
      expect(find.text(ScoreSummaryCard.unavailableTitle), findsOneWidget);
      expect(
        find.text('• Dinh dưỡng của sản phẩm sau khi pha chế'),
        findsOneWidget,
      );
      expect(
        find.text('Dinh dưỡng Chưa đủ dữ liệu · trọng số 70%'),
        findsOneWidget,
      );
      expect(find.text('Phụ gia 0/100 · trọng số 30%'), findsOneWidget);
      expect(
        find.text('Đây là điểm thành phần, chưa phải Điểm Fluw tổng.'),
        findsOneWidget,
      );
      expect(find.textContaining('×'), findsNothing);
    },
  );

  testWidgets('không áp dụng (bia): nói rõ lý do, dinh dưỡng trên 100 ml', (
    tester,
  ) async {
    await _show(tester, 'product-not-applicable');

    expect(find.text(ScoreSummaryCard.unavailableTitle), findsOneWidget);
    expect(
      find.text(
        'Cách tính điểm dinh dưỡng không áp dụng cho loại sản phẩm này.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Dinh dưỡng Không áp dụng · trọng số 70%'),
      findsOneWidget,
    );
    await _scrollTo(tester, find.text('Dinh dưỡng trên 100 ml'));
  });

  testWidgets(
    'nước: thiếu mọi chỉ số dinh dưỡng thì ghi chưa có dữ liệu, không hiện số 0',
    (tester) async {
      await _show(tester, 'product-water');

      expect(find.text('100'), findsOneWidget);
      await _scrollTo(tester, find.textContaining('là chưa có dữ liệu'));
      expect(
        find.bySemanticsLabel('Chất đạm: chưa có dữ liệu'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Muối: chưa có dữ liệu'), findsOneWidget);
      await _scrollTo(tester, find.text(AdditivesSection.noneVerified));
    },
  );

  testWidgets(
    'thiếu thành phần và danh mục: ghi "Chưa có dữ liệu", không đoán, không ẩn mục dị ứng',
    (tester) async {
      await _show(tester, 'product-missing-category');

      await _scrollTo(
        tester,
        find.bySemanticsLabel('Năng lượng (kJ): 1.715,4 kilojun'),
      );
      await _scrollTo(tester, find.text('Thành phần'));
      await _scrollTo(tester, find.text('Chất gây dị ứng theo nhãn'));
      await _scrollTo(tester, find.text('Có thể chứa'));
      await _scrollTo(tester, find.text('Phụ gia'));
      expect(find.text(AdditivesSection.noneVerified), findsNothing);
      expect(find.text('Chưa có dữ liệu'), findsWidgets);
      await _scrollTo(tester, find.text('Chủ sở hữu thương hiệu'));
      expect(find.text('Ảnh sản phẩm'), findsNothing);
    },
  );

  for (final Size size in [phoneSize, const Size(320, 640)]) {
    testWidgets(
      'cỡ chữ hệ thống 200% vẫn không tràn bố cục (${size.width.toInt()} px)',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        for (final String fixture in [
          'product-food-complete',
          'product-missing-category',
        ]) {
          await _show(tester, fixture, size: size);
          expect(tester.takeException(), isNull);
          await _scrollTo(tester, find.text(DataSourceFooter.copyLabel));
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('tiêu đề các mục được đọc là tiêu đề (heading)', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _show(tester, 'product-food-complete');
    await _scrollTo(tester, find.text('Dinh dưỡng trên 100 g'));

    expect(
      tester.getSemantics(find.text('Dinh dưỡng trên 100 g')),
      matchesSemantics(label: 'Dinh dưỡng trên 100 g', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('sao chép link sản phẩm Open Food Facts vào clipboard', (
    tester,
  ) async {
    final List<Object?> copied = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text']);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _show(tester, 'product-food-complete');
    await _scrollTo(tester, find.text(DataSourceFooter.copyLabel));
    await tester.tap(find.text(DataSourceFooter.copyLabel));
    await tester.pump();

    expect(copied, ['https://world.openfoodfacts.org/product/8930000000019']);
    expect(find.text(DataSourceFooter.copiedMessage), findsOneWidget);
  });

  testWidgets('thiếu thương hiệu thì dòng phụ không thừa dấu "·"', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      ProductDetailView(
        details: productDetails(
          'product-food-complete',
          edit: (product, _) => product['brand'] = null,
        ),
      ),
    );

    expect(find.text('120 g · 8930000000019'), findsOneWidget);
  });

  testWidgets(
    'trình đọc màn hình đọc "Điểm tổng X trên 100, mức …", tên sản phẩm là tiêu đề',
    (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _show(tester, 'product-food-complete');

      expect(
        find.bySemanticsLabel('Điểm tổng 31 trên 100, mức Nên hạn chế'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.text('Bánh quy bơ (dữ liệu thử)')),
        matchesSemantics(label: 'Bánh quy bơ (dữ liệu thử)', isHeader: true),
      );
      semantics.dispose();
    },
  );

  testWidgets('tên sản phẩm rất dài trên màn hình hẹp không làm tràn bố cục', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      ProductDetailView(
        details: productDetails(
          'product-food-complete',
          edit: (product, _) => product['name'] = 'Bánh quy yến mạch nguyên hạt vị mật ong và hạt chia hộp lớn 500 g',
        ),
      ),
      size: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('thiếu tên sản phẩm thì ghi rõ', (tester) async {
    await pumpOnPhone(
      tester,
      ProductDetailView(
        details: productDetails(
          'product-water',
          edit: (product, _) => product['name'] = null,
        ),
      ),
    );

    expect(find.text(ProductHeader.missingName), findsOneWidget);
  });

  testWidgets('nút "Cách Fluw tính điểm" mở màn giải thích', (tester) async {
    await _show(tester, 'product-food-complete');

    await tester.tap(find.text(ScoreSummaryCard.explainLabel));
    await tester.pumpAndSettle();

    expect(find.byType(ScoreExplanationScreen), findsOneWidget);
  });

  testWidgets('ảnh dùng cỡ nhỏ; chỉ khi mở phóng to mới tải ảnh gốc', (
    tester,
  ) async {
    await _show(tester, 'product-food-complete');

    final List<String> before = _networkUrls(tester);
    expect(before.where((url) => url.endsWith('.full.jpg')), isEmpty);
    expect(
      before.where((url) => url.endsWith('front_vi.5.200.jpg')),
      isNotEmpty,
    );

    await tester.tap(find.bySemanticsLabel('Phóng to ảnh sản phẩm'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductImageScreen), findsOneWidget);
    expect(
      _networkUrls(tester).where((url) => url.endsWith('front_vi.5.full.jpg')),
      isNotEmpty,
    );
  });

  testWidgets(
    'ảnh ngoài máy chủ ảnh Open Food Facts không được tải, hiện ảnh giữ chỗ',
    (tester) async {
      await pumpOnPhone(
        tester,
        ProductDetailView(
          details: productDetails(
            'product-food-complete',
            edit: (product, _) => product['images'] = {
              'front': {
                'small': 'https://evil.example/a.jpg',
                'display': null,
                'full': 'https://evil.example/b.jpg',
              },
            },
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(
        tester.widget<ProductThumbnail>(find.byType(ProductThumbnail)).onTap,
        isNull,
      );
    },
  );
}
