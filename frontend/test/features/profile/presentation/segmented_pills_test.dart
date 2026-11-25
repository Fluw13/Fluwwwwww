import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/features/profile/presentation/segmented_pills.dart';

import '../../../helpers/load_app_fonts.dart';

void main() {
  Future<List<String>> pump(WidgetTester tester, {double width = 326, String? selected = 'Nam'}) async {
    final picked = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: StatefulBuilder(
                builder: (context, setState) => SegmentedPills<String>(
                  options: const {'Nam': 'Nam', 'Nữ': 'Nữ', 'Khác': 'Khác'},
                  selected: selected,
                  onSelected: (value) => setState(() {
                    picked.add(value);
                    selected = value;
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return picked;
  }

  testWidgets('chạm một lựa chọn thì báo giá trị đó và đánh dấu bằng dấu tích, không chỉ bằng màu', (tester) async {
    final picked = await pump(tester);

    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('Khác'));
    await tester.pump();

    expect(picked, ['Khác']);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      tester.getCenter(find.byIcon(Icons.check)).dx,
      lessThan(tester.getCenter(find.text('Khác')).dx),
      reason: 'dấu tích nằm trong lựa chọn vừa chạm',
    );
  });

  testWidgets('mỗi lựa chọn là nút có trạng thái chọn, trong nhóm loại trừ, cao ít nhất 48 dp', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.text('Nam')),
      isSemantics(
        label: 'Nam',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Nữ')),
      isSemantics(label: 'Nữ', isButton: true, hasSelectedState: true, isSelected: false, hasTapAction: true),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('chữ quá to so với chỗ: các lựa chọn xếp chồng, không tràn', (tester) async {
    await loadAppFonts();
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, width: 256);

    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(find.text('Nữ')).dy, greaterThan(tester.getBottomLeft(find.text('Nam')).dy));
  });

  testWidgets('đủ chỗ thì các lựa chọn nằm cùng một hàng', (tester) async {
    await pump(tester);

    expect(tester.getCenter(find.text('Nữ')).dy, tester.getCenter(find.text('Nam')).dy);
  });
}
