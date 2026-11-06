import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/content/legal_pages.dart';
import 'package:frontend/core/history/session_history.dart';
import 'package:frontend/core/settings/theme_mode_controller.dart';
import 'package:frontend/core/support/support_contact.dart';
import 'package:frontend/models/product_summary.dart';
import 'package:frontend/screens/account_screen.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/info_page_screen.dart';

import '../helpers/fluw_app_harness.dart';

Future<void> _tapRow(WidgetTester tester, String title) async {
  final Finder row = find.text(title);
  await tester.scrollUntilVisible(row, 200);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('đăng nhập hiện "Sắp có" và bị khóa, không có luồng đăng nhập giả', (tester) async {
    await pumpFluwApp(tester, const AccountScreen());

    final FilledButton login = tester.widget(find.widgetWithText(FilledButton, 'Đăng nhập · Sắp có'));
    expect(login.onPressed, isNull);
  });

  testWidgets('chọn Tối thì đổi giao diện ngay và lưu lại trên máy', (tester) async {
    final MemoryThemeModeStore store = MemoryThemeModeStore();
    final ThemeModeController controller = await pumpFluwApp(tester, const AccountScreen(), store: store);

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    expect(controller.mode, ThemeMode.dark);
    expect(store.value, ThemeMode.dark);
    expect(Theme.of(tester.element(find.byType(AccountScreen))).brightness, Brightness.dark);
  });

  testWidgets('mục lịch sử hiện số mục trong phiên và ghi rõ chỉ lưu trong phiên', (tester) async {
    final SessionHistory history = SessionHistory()
      ..addScan(const ProductSummary(barcode: '1', name: 'A', brand: '', imageUrl: ''))
      ..addSearch('mì');
    await pumpFluwApp(tester, const AccountScreen(), history: history);

    expect(find.text('Lịch sử quét'), findsOneWidget);
    expect(find.text('1 mục'), findsNWidgets(2));
    expect(find.text(HistoryScreen.sessionNote), findsOneWidget);

    await tester.tap(find.text('Lịch sử tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('mì'), findsOneWidget);
  });

  testWidgets('bấm liên hệ hỗ trợ thì chép email và báo đã chép; email mẫu được ghi rõ là mẫu', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpFluwApp(tester, const AccountScreen());
    final Finder support = find.text('Liên hệ hỗ trợ và góp ý');
    await tester.scrollUntilVisible(support, 200);
    await tester.ensureVisible(support);
    await tester.pumpAndSettle();
    await tester.tap(support);
    await tester.pump();

    expect(copied, SupportContact.email);
    expect(find.text('Đã chép ${SupportContact.email}'), findsOneWidget);
    expect(SupportContact.isSample, isTrue);
    expect(find.textContaining('Địa chỉ mẫu'), findsOneWidget);
  });

  for (final String title in [
    LegalPages.terms.title,
    LegalPages.privacy.title,
    LegalPages.dataSources.title,
    LegalPages.aiDisclaimer.title,
  ]) {
    testWidgets('mở trang "$title"', (tester) async {
      await pumpFluwApp(tester, const AccountScreen());

      await _tapRow(tester, title);

      expect(find.byType(InfoPageScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, title), findsOneWidget);
    });
  }

  testWidgets('mở danh sách giấy phép mã nguồn mở', (tester) async {
    await pumpFluwApp(tester, const AccountScreen());

    await _tapRow(tester, 'Giấy phép mã nguồn mở');

    expect(find.byType(LicensePage), findsOneWidget);
  });

  for (final ThemeMode mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('màn 320 px, chữ 200% (${mode.name}): không tràn khi cuộn hết trang', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpFluwApp(tester, const AccountScreen(), themeMode: mode);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Giấy phép mã nguồn mở'), 300);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('trình đọc màn hình báo bấm dòng hỗ trợ sẽ chép email', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpFluwApp(tester, const AccountScreen());

    final Finder support = find.text('Liên hệ hỗ trợ và góp ý');
    await tester.scrollUntilVisible(support, 200);
    expect(tester.getSemantics(support), isSemantics(isButton: true, onTapHint: 'chép email'));
    semantics.dispose();
  });
}
