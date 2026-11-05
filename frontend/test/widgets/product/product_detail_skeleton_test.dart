import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/product/nutrition_grid.dart';
import 'package:frontend/widgets/product/product_detail_skeleton.dart';
import 'package:frontend/widgets/product/product_detail_view.dart';
import 'package:frontend/widgets/product/product_header.dart';
import 'package:frontend/widgets/product/score_summary_card.dart';
import 'package:frontend/widgets/skeleton/shimmer_scope.dart';
import 'package:frontend/widgets/skeleton/skeleton_box.dart';

import '../../helpers/product_fixtures.dart';
import '../../helpers/test_app.dart';

/// Top-left corner and width of each section, in screen coordinates.
Map<Type, Rect> _sectionRects(WidgetTester tester) {
  return {
    for (final Type type in [ScoreSummaryCard, ProductHeader, NutritionGrid])
      type: tester.getRect(find.byType(type).first),
  };
}

/// A product with a total score whose texts take one line, so its real
/// sections have the same height as the skeleton's one-line placeholders.
final _oneLineProduct = productDetails(
  'product-yogurt-good',
  edit: (product, score) {
    product['name'] = 'Sữa chua';
    product['brand'] = 'A';
  },
);

/// The test font rounds every text line up to whole pixels while a skeleton
/// line is exactly fontSize × height, so a section with several lines (the
/// score card has six) can differ by a little over 1 px in tests only.
const double _tolerance = 2;

void main() {
  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'skeleton dựng được, có shimmer, không lộ ra trình đọc màn hình (${mode.name})',
      (tester) async {
        await pumpOnPhone(
          tester,
          const ProductDetailSkeleton(),
          themeMode: mode,
        );

        expect(find.byType(ShimmerScope), findsOneWidget);
        expect(find.byType(SkeletonBox), findsWidgets);
        expect(tester.hasRunningAnimations, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final double textScale in [1.0, 2.0]) {
    testWidgets(
      'mỗi khối skeleton nằm đúng chỗ nội dung thật sẽ hiện (chữ ${textScale}x)',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        // The test font draws every glyph 1 em wide, so on a 390 px phone the
        // score lines ("Dinh dưỡng 79/100 · trọng số 70%", the calculation)
        // wrap where Be Vietnam Pro does not. At 1x a wider screen gives them
        // the room they have on a real phone.
        final Size size = textScale == 1.0 ? const Size(640, 1200) : phoneSize;

        await pumpOnPhone(tester, const ProductDetailSkeleton(), size: size);
        final Map<Type, Rect> skeleton = _sectionRects(tester);

        await pumpOnPhone(
          tester,
          ProductDetailView(details: _oneLineProduct),
          size: size,
        );
        final Map<Type, Rect> content = _sectionRects(tester);

        // With very large text the score card's real lines (component scores,
        // calculation) may wrap, which a skeleton cannot know in advance, and
        // every section below moves with it. So at 2x only the score card,
        // which starts the page, must line up exactly.
        final List<Type> mustAlign = textScale == 1.0
            ? [ScoreSummaryCard, ProductHeader, NutritionGrid]
            : [ScoreSummaryCard];

        for (final Type type in mustAlign) {
          expect(
            skeleton[type]!.left,
            content[type]!.left,
            reason: '$type left',
          );
          expect(
            skeleton[type]!.width,
            content[type]!.width,
            reason: '$type width',
          );
          expect(
            skeleton[type]!.top,
            moreOrLessEquals(content[type]!.top, epsilon: _tolerance),
            reason: '$type top',
          );
        }
        if (textScale == 1.0) {
          for (final Type type in [ScoreSummaryCard, NutritionGrid]) {
            expect(
              skeleton[type]!.height,
              moreOrLessEquals(content[type]!.height, epsilon: _tolerance),
              reason: '$type height',
            );
          }
        }
      },
    );
  }
}
