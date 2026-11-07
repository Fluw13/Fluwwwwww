import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/fns_result.dart';
import 'package:frontend/widgets/ai_unavailable_card.dart';
import 'package:frontend/widgets/circular_score_ring.dart';
import 'package:frontend/widgets/product/fns_breakdown_card.dart';
import 'package:frontend/widgets/product/fns_not_scored_card.dart';
import 'package:frontend/widgets/product/product_detail_view.dart';
import 'package:frontend/widgets/product/score_summary_card.dart';
import 'package:frontend/widgets/zero_analysis_card.dart';

import '../../helpers/product_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('đủ dữ liệu: hiện điểm, sản phẩm, dinh dưỡng, phân tích và nhãn (${mode.name})', (tester) async {
      await pumpOnPhone(tester, ProductDetailView(product: buildProduct()), themeMode: mode);

      expect(find.byType(ScoreSummaryCard), findsOneWidget);
      expect(find.text('7,8'), findsOneWidget);
      expect(find.text('/10'), findsOneWidget);
      expect(find.text('Cao'), findsOneWidget);
      expect(find.text('Tạm tính'), findsOneWidget);
      expect(find.text('Nhóm so sánh: Thực phẩm đóng gói'), findsOneWidget);
      expect(find.text('Do AI tạo'), findsOneWidget, reason: 'chỉ thẻ Zero được ghi do AI tạo, thẻ điểm thì không');
      expect(find.text('Bánh quy yến mạch'), findsOneWidget);
      expect(find.text('Thương hiệu mẫu · 8934563138165'), findsOneWidget);
      expect(find.text('Dinh dưỡng trên 100 g'), findsOneWidget);
      expect(find.bySemanticsLabel('Chất đạm: 9,8 gam'), findsOneWidget);
      expect(find.byType(ZeroAnalysisCard), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Sữa'), 300);
      expect(find.text('Gluten'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cùng một khung cho sản phẩm khác: chỉ dữ liệu thay đổi', (tester) async {
    await pumpOnPhone(
      tester,
      ProductDetailView(product: buildProduct(name: 'Nước ngọt có ga', score: 2.2, calories: 42)),
    );

    expect(find.text('Nước ngọt có ga'), findsOneWidget);
    expect(find.text('2,2'), findsOneWidget);
    expect(find.text('Thấp'), findsOneWidget);
    expect(find.bySemanticsLabel('Năng lượng: 42 kilocalo'), findsOneWidget);
  });

  testWidgets('không có AI: điểm FNS vẫn hiện, thay thẻ Zero bằng thông báo, ẩn phần do AI gợi ý', (tester) async {
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct(aiError: 'AI_RATE_LIMITED')));

    expect(find.byType(ScoreSummaryCard), findsOneWidget);
    expect(find.text('7,8'), findsOneWidget);
    expect(find.byType(AiUnavailableCard), findsOneWidget);
    expect(find.byType(ZeroAnalysisCard), findsNothing);
    expect(find.text('Có thể chứa thêm (AI gợi ý)'), findsNothing);
    expect(find.bySemanticsLabel('Chất béo: 14,2 gam'), findsOneWidget);
  });

  testWidgets('chưa chấm điểm: không vẽ vòng điểm, không hiện 0, nêu rõ dữ liệu còn thiếu', (tester) async {
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct(score: null)));

    expect(find.byType(FnsNotScoredCard), findsOneWidget);
    expect(find.byType(ScoreSummaryCard), findsNothing);
    expect(find.byType(CircularScoreRing), findsNothing);
    expect(find.byType(FnsBreakdownCard), findsNothing);
    expect(find.text('Chưa đủ dữ liệu để chấm điểm'), findsOneWidget);
    expect(find.text('Còn thiếu: natri.'), findsOneWidget);
    expect(find.textContaining('0,0'), findsNothing);
    expect(find.byType(ZeroAnalysisCard), findsOneWidget, reason: 'phân tích AI không phụ thuộc vào điểm');
  });

  testWidgets('sản phẩm ngoài phạm vi: nói rõ Fluw chưa chấm nhóm này', (tester) async {
    const FnsResult outOfScope = FnsResult(status: FnsStatus.notScored, reasonCodes: ['OUT_OF_SCOPE']);
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct(fns: outOfScope)));

    expect(find.text('Fluw chưa chấm điểm nhóm sản phẩm này'), findsOneWidget);
    expect(find.textContaining('đồ uống có cồn'), findsOneWidget);
  });

  testWidgets('thẻ "Cách Fluw tính điểm" hiện điểm cộng, điểm trừ, tổng và giới hạn dữ liệu', (tester) async {
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct()));

    final Finder card = find.byType(FnsBreakdownCard);
    await tester.scrollUntilVisible(find.text('Cách Fluw tính điểm'), 300);
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('+4')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('−5')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('−8')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('-3')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.textContaining('12 g')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.textContaining('Dữ liệu cộng đồng')), findsOneWidget);
  });

  testWidgets('đạm hoặc xơ không đủ điều kiện thì ghi "Không tính", không ghi 0', (tester) async {
    const FnsResult drink = FnsResult(
      status: FnsStatus.provisional,
      score: 0,
      category: 'C1',
      basis: 'per_100ml',
      rawScore: 14,
      baselineComponents: ['energy', 'total_sugars'],
      componentPoints: {'energy': 6, 'total_sugars': 8, 'fvnl': 0, 'protein': null, 'fiber': null},
      proteinEligible: false,
    );
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct(fns: drink)));
    await tester.scrollUntilVisible(find.text('Cách Fluw tính điểm'), 300);

    final Finder card = find.byType(FnsBreakdownCard);
    expect(find.descendant(of: card, matching: find.text('Không tính')), findsNWidgets(2));
    expect(find.descendant(of: card, matching: find.textContaining('Natri')), findsNothing);
    expect(find.textContaining('100 ml'), findsOneWidget);
  });

  testWidgets('thiếu dinh dưỡng thì ghi rõ chưa có dữ liệu, không hiện số 0', (tester) async {
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct(protein: null, carbs: null)));

    expect(find.bySemanticsLabel('Chất đạm: chưa có dữ liệu'), findsOneWidget);
    expect(find.bySemanticsLabel('Carbohydrate: chưa có dữ liệu'), findsOneWidget);
    expect(find.textContaining('là chưa có dữ liệu'), findsOneWidget);
  });

  testWidgets('danh sách rỗng thì ẩn cả mục, không để tiêu đề trống', (tester) async {
    await pumpOnPhone(
      tester,
      ProductDetailView(
        product: buildProduct(declaredAllergens: const [], suggestedAllergens: const []),
      ),
    );

    expect(find.text('Chất gây dị ứng theo nhãn'), findsNothing);
    expect(find.text('Có thể chứa thêm (AI gợi ý)'), findsNothing);
  });

  for (final Size size in [phoneSize, const Size(320, 640)]) {
    testWidgets('cỡ chữ hệ thống 200% vẫn không tràn bố cục (${size.width.toInt()} px)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpOnPhone(tester, ProductDetailView(product: buildProduct()), size: size);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Sữa'), 300);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('có điểm nhưng AI không viết gì thì không hiện thẻ Zero rỗng', (tester) async {
    await pumpOnPhone(
      tester,
      ProductDetailView(
        product: buildProduct(deepThink: '', recommendation: ''),
      ),
    );

    expect(find.byType(ScoreSummaryCard), findsOneWidget);
    expect(find.byType(ZeroAnalysisCard), findsNothing);
  });

  testWidgets('tiêu đề các mục được đọc là tiêu đề (heading)', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct()));

    expect(
      tester.getSemantics(find.text('Dinh dưỡng trên 100 g')),
      matchesSemantics(label: 'Dinh dưỡng trên 100 g', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('luôn ghi nguồn Open Food Facts (ODbL) và giấy phép ảnh ở cuối trang', (tester) async {
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct(score: null)));

    await tester.scrollUntilVisible(find.textContaining('ODbL'), 300);
    expect(find.textContaining('Open Food Facts (openfoodfacts.org)'), findsOneWidget);
    expect(find.textContaining('CC BY-SA'), findsOneWidget);
  });

  testWidgets('thiếu thương hiệu thì dòng phụ chỉ có mã vạch, không thừa dấu "·"', (tester) async {
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct(brand: '')));

    expect(find.text('8934563138165'), findsOneWidget);
    expect(find.textContaining('· 8934563138165'), findsNothing);
  });

  testWidgets('trình đọc màn hình đọc điểm là "Điểm X trên 10", tên sản phẩm là tiêu đề', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpOnPhone(tester, ProductDetailView(product: buildProduct()));

    expect(find.bySemanticsLabel('Điểm 7,8 trên 10'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Bánh quy yến mạch')),
      matchesSemantics(label: 'Bánh quy yến mạch', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('tên sản phẩm rất dài trên màn hình hẹp không làm tràn bố cục', (tester) async {
    await pumpOnPhone(
      tester,
      ProductDetailView(
        product: buildProduct(name: 'Bánh quy yến mạch nguyên hạt vị mật ong và hạt chia hộp lớn 500 g'),
      ),
      size: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
  });
}
