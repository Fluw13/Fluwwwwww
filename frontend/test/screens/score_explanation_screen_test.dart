import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/score_explanation_screen.dart';
import 'package:frontend/widgets/score/indicator_row.dart';

import '../helpers/product_fixtures.dart';
import '../helpers/test_app.dart';

Future<void> _open(
  WidgetTester tester,
  String fixture, {
  Size size = phoneSize,
}) {
  return pumpScreen(
    tester,
    ScoreExplanationScreen(details: productDetails(fixture)),
    size: size,
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 300);

void main() {
  testWidgets(
    'đủ dữ liệu: tổng, công thức, đường đi điểm thô → dải → điểm dinh dưỡng',
    (tester) async {
      await _open(tester, 'product-food-complete');

      expect(find.text('31/100'), findsOneWidget);
      expect(find.text('Nên hạn chế'), findsOneWidget);
      expect(
        find.textContaining(
          'Điểm Fluw = Điểm dinh dưỡng × 70% + Điểm phụ gia × 30%',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Phép tính: 18 × 0,7 + 60 × 0,3 = 30,6 → 31'),
        findsOneWidget,
      );
      expect(find.text('Loại sản phẩm: Thực phẩm'), findsOneWidget);
      expect(find.text('Tính trên sản phẩm như khi bán.'), findsOneWidget);
      expect(
        find.text('Điểm trừ 21 − điểm cộng 0 = điểm thô 21.'),
        findsOneWidget,
      );
      expect(
        find.text('Điểm thô thuộc dải 19 … 55, ứng với điểm dinh dưỡng 0–19.'),
        findsOneWidget,
      );
      expect(find.text('→ Điểm dinh dưỡng 18/100.'), findsOneWidget);
    },
  );

  testWidgets(
    'mỗi chỉ số: giá trị/100, khoảng ngưỡng có biên đóng/mở, điểm, chiều, trạng thái, ghi chú',
    (tester) async {
      await _open(tester, 'product-food-complete');

      await _scrollTo(tester, find.text('Khoảng ngưỡng: > 1.675 – ≤ 2.010 kJ'));
      expect(find.text('2.000 kJ/100 g'), findsOneWidget);
      expect(find.text('5/10 điểm'), findsOneWidget);
      expect(find.text('Điểm trừ · Đã tính'), findsWidgets);

      await _scrollTo(tester, find.text('Khoảng ngưỡng: > 0,4 – ≤ 0,6 g'));
      expect(find.text('0,5 g/100 g'), findsOneWidget);

      await _scrollTo(tester, find.text('Điểm cộng · Không tính theo quy tắc'));
      expect(
        find.text(
          'Không tính vì tổng điểm trừ từ 11 trở lên (quy tắc Nutri-Score).',
        ),
        findsOneWidget,
      );
      await _scrollTo(tester, find.text('Khoảng ngưỡng: ≤ 3 g'));
      await _scrollTo(tester, find.text('Điểm cộng · Ước tính'));
      expect(find.text('Khoảng ngưỡng: ≤ 40%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    },
  );

  testWidgets(
    'phụ gia: số lượng, mốc điểm, danh sách mã E; NOVA không tính vào điểm; nguồn; miễn trừ',
    (tester) async {
      await _open(tester, 'product-food-complete');

      await _scrollTo(tester, find.text('Mốc điểm: 3–4 phụ gia → 60 điểm.'));
      expect(find.text('Số phụ gia khác nhau: 4.'), findsOneWidget);
      await _scrollTo(
        tester,
        find.text('E471 · Mono- và diglycerid của axit béo'),
      );
      await _scrollTo(tester, find.text('Nhóm 4 trên thang 1–4.'));
      expect(
        find.text('Chỉ để tham khảo, không tính vào điểm.'),
        findsOneWidget,
      );
      await _scrollTo(
        tester,
        find.text('Open Food Facts · ODbL · ảnh CC BY-SA'),
      );
      expect(
        find.text('Cập nhật trên Open Food Facts: 30/10/2025'),
        findsOneWidget,
      );
      expect(find.text('Phiên bản công thức: fluw-score-1.0'), findsOneWidget);
      await _scrollTo(
        tester,
        find.textContaining('không phải chẩn đoán hay tư vấn y tế'),
      );
    },
  );

  testWidgets(
    'thiếu danh mục và thành phần: không có điểm tổng, liệt kê mục thiếu, không có bảng chỉ số',
    (tester) async {
      await _open(tester, 'product-missing-category');

      expect(find.text('Chưa đủ dữ liệu để tính điểm tổng.'), findsOneWidget);
      expect(find.textContaining('Phép tính'), findsNothing);
      expect(find.text('Loại sản phẩm: Chưa xác định'), findsOneWidget);
      expect(
        find.text('Chưa đủ dữ liệu để tính điểm dinh dưỡng.'),
        findsOneWidget,
      );
      expect(find.byType(IndicatorRow), findsNothing);
      await _scrollTo(
        tester,
        find.text(
          'Chưa có danh sách thành phần nên chưa tính được điểm phụ gia.',
        ),
      );
      await _scrollTo(tester, find.text('Còn thiếu dữ liệu'));
      expect(find.text('• Danh sách thành phần'), findsWidgets);
      await _scrollTo(tester, find.text('Chưa có dữ liệu.'));
    },
  );

  testWidgets('nước: nói rõ quy tắc 100 điểm, không có bảng chỉ số', (
    tester,
  ) async {
    await _open(tester, 'product-water');

    expect(
      find.text(
        'Nước luôn được 100/100 điểm dinh dưỡng, không tính theo chỉ số.',
      ),
      findsOneWidget,
    );
    expect(find.byType(IndicatorRow), findsNothing);
  });

  testWidgets(
    'đồ uống: giá trị trên 100 ml, chất tạo ngọt đếm theo số chất, không có khoảng ngưỡng',
    (tester) async {
      await _open(tester, 'product-beverage');

      await _scrollTo(tester, find.text('180 kJ/100 ml'));
      await _scrollTo(tester, find.text('Chất tạo ngọt không đường'));
      expect(find.text('0 chất'), findsOneWidget);
    },
  );

  testWidgets('mỗi chỉ số được trình đọc màn hình đọc thành một mục', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _open(tester, 'product-food-complete');
    await _scrollTo(tester, find.byType(IndicatorRow).first);

    expect(
      tester.getSemantics(find.byType(IndicatorRow).first),
      isSemantics(
        label: 'Năng lượng\n5/10 điểm\n2.000 kJ/100 g\nKhoảng ngưỡng: > 1.675 – ≤ 2.010 kJ\nĐiểm trừ · Đã tính',
      ),
    );
    semantics.dispose();
  });

  for (final Size size in [const Size(360, 640), const Size(320, 640)]) {
    testWidgets('chữ 200% không tràn (${size.width.toInt()} px)', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final String fixture in [
        'product-food-complete',
        'product-missing-category',
      ]) {
        await _open(tester, fixture, size: size);
        expect(tester.takeException(), isNull);
        await _scrollTo(tester, find.textContaining('tư vấn y tế'));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
