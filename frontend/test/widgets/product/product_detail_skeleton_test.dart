import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/product/nutrition_grid.dart';
import 'package:frontend/widgets/product/product_detail_skeleton.dart';
import 'package:frontend/widgets/product/product_detail_view.dart';
import 'package:frontend/widgets/product/product_header.dart';
import 'package:frontend/widgets/product/score_summary_card.dart';
import 'package:frontend/widgets/skeleton/shimmer_scope.dart';
import 'package:frontend/widgets/skeleton/skeleton_box.dart';
import 'package:frontend/widgets/zero_analysis_card.dart';

import '../../helpers/product_fixtures.dart';
import '../../helpers/test_app.dart';

/// Top-left corner and width of each section, in screen coordinates.
Map<Type, Rect> _sectionRects(WidgetTester tester) {
  return {
    for (final Type type in [ScoreSummaryCard, ProductHeader, NutritionGrid, ZeroAnalysisCard])
      type: tester.getRect(find.byType(type).first),
  };
}

/// A product whose texts take one line, so its real sections have the same
/// height as the skeleton's one-line placeholders.
final _oneLineProduct = buildProduct(name: 'Sữa', brand: 'A', barcode: '');

void main() {
  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('skeleton dựng được, có shimmer, không lộ ra trình đọc màn hình (${mode.name})', (tester) async {
      await pumpOnPhone(tester, const ProductDetailSkeleton(), themeMode: mode);

      expect(find.byType(ShimmerScope), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(tester.hasRunningAnimations, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  for (final double textScale in [1.0, 2.0]) {
    testWidgets('mỗi khối skeleton nằm đúng chỗ nội dung thật sẽ hiện (chữ ${textScale}x)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpOnPhone(tester, const ProductDetailSkeleton());
      final Map<Type, Rect> skeleton = _sectionRects(tester);

      await pumpOnPhone(tester, ProductDetailView(product: _oneLineProduct));
      final Map<Type, Rect> content = _sectionRects(tester);

      // With very large text a real value such as "412 kcal" may wrap onto a
      // second line, which a skeleton cannot know in advance. So at 2x only the
      // sections that do not depend on data length must line up exactly.
      final List<Type> mustAlign = textScale == 1.0
          ? [ScoreSummaryCard, ProductHeader, NutritionGrid, ZeroAnalysisCard]
          : [ScoreSummaryCard, ProductHeader, NutritionGrid];

      for (final Type type in mustAlign) {
        expect(skeleton[type]!.left, content[type]!.left, reason: '$type left');
        expect(skeleton[type]!.width, content[type]!.width, reason: '$type width');
        expect(skeleton[type]!.top, moreOrLessEquals(content[type]!.top, epsilon: 1), reason: '$type top');
      }
      if (textScale == 1.0) {
        expect(
          skeleton[NutritionGrid]!.height,
          moreOrLessEquals(content[NutritionGrid]!.height, epsilon: 1),
          reason: 'nutrition grid height',
        );
      }
    });
  }
}
