import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/content/info_page.dart';
import 'package:frontend/content/legal_pages.dart';
import 'package:frontend/screens/info_page_screen.dart';

import '../helpers/fluw_app_harness.dart';

void main() {
  testWidgets('trang có ghi chú trạng thái thì hiện ghi chú trước nội dung', (tester) async {
    await pumpFluwApp(tester, const InfoPageScreen(page: LegalPages.terms));

    expect(find.text(LegalPages.terms.notice!), findsOneWidget);
    expect(find.text('Trong lúc chờ bản chính thức'), findsOneWidget);
  });

  testWidgets('trang nguồn dữ liệu ghi rõ ODbL và CC BY-SA', (tester) async {
    await pumpFluwApp(tester, const InfoPageScreen(page: LegalPages.dataSources));

    expect(find.textContaining('Open Database License (ODbL)'), findsOneWidget);
    expect(find.textContaining('Creative Commons BY-SA'), findsOneWidget);
  });

  testWidgets('tiêu đề các mục là heading với trình đọc màn hình', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpFluwApp(tester, const InfoPageScreen(page: LegalPages.privacy));

    expect(
      tester.getSemantics(find.text('Camera')),
      matchesSemantics(label: 'Camera', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('chính sách nói rõ lịch sử chỉ trong phiên, không gửi đi', (tester) async {
    await pumpFluwApp(tester, const InfoPageScreen(page: LegalPages.privacy));

    await tester.scrollUntilVisible(find.textContaining('mất khi bạn đóng ứng dụng'), 200);
    expect(find.textContaining('không gửi đi đâu'), findsOneWidget);
  });

  for (final InfoPage page in [LegalPages.terms, LegalPages.privacy, LegalPages.dataSources, LegalPages.aiDisclaimer]) {
    testWidgets('"${page.title}": màn 320 px, chữ 200% không tràn khi cuộn hết', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpFluwApp(tester, InfoPageScreen(page: page));
      await tester.scrollUntilVisible(find.text(page.sections.last.paragraphs.last), 300);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('chính sách nói rõ nhật ký kỹ thuật của hosting', (tester) async {
    await pumpFluwApp(tester, const InfoPageScreen(page: LegalPages.privacy));

    await tester.scrollUntilVisible(find.textContaining('nhật ký kỹ thuật'), 200);
    expect(find.textContaining('đường dẫn yêu cầu'), findsOneWidget);
  });
}
