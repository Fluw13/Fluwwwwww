import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/shell/fluw_bottom_bar.dart';
import 'package:fluw/features/privacy/presentation/privacy_policy_text.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';

import '../features/profile/domain/profile_fixture.dart';
import '../helpers/load_app_fonts.dart';
import '../helpers/pump_fluw_app.dart';
import '../helpers/scroll_to.dart';

const String _privacyButton = 'Quyền riêng tư và điều khoản';

void main() {
  Future<void> openProfileTab(WidgetTester tester, {bool withProfile = false}) async {
    await pumpFluwApp(tester);
    if (withProfile) {
      await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
  }

  void expectPrivacyScreen(WidgetTester tester) {
    expect(find.text(PrivacyPolicy.title), findsOneWidget);
    expect(find.byType(FluwBottomBar).hitTestable(), findsNothing, reason: 'toàn màn hình, che thanh tab');
    expect(find.widgetWithText(SelectableText, PrivacyPolicy.publicUrl), findsOneWidget);
    expect(find.widgetWithText(SelectableText, PrivacyPolicy.issuesUrl), findsOneWidget);
  }

  testWidgets('Hồ Sơ → Về Fluw: lời miễn trừ y tế và nút mở màn quyền riêng tư có địa chỉ chọn được', (tester) async {
    await openProfileTab(tester, withProfile: true);
    await scrollTo(tester, find.text(_privacyButton));
    expect(find.textContaining('Fluw không phải thiết bị y tế'), findsOneWidget);

    await tester.tap(find.text(_privacyButton));
    await tester.pumpAndSettle();
    expectPrivacyScreen(tester);
    await scrollTo(tester, find.text('9. Thay đổi chính sách'));
    expect(find.textContaining('app sẽ báo cho bạn', findRichText: true), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(PrivacyPolicy.title), findsNothing);
  });

  testWidgets('màn chưa có hồ sơ cũng mở được màn quyền riêng tư', (tester) async {
    await openProfileTab(tester);
    expect(find.text('Chưa có hồ sơ sức khỏe'), findsOneWidget);

    await scrollTo(tester, find.text(_privacyButton));
    await tester.tap(find.text(_privacyButton));
    await tester.pumpAndSettle();

    expectPrivacyScreen(tester);
  });

  testWidgets('nút sao chép chép đúng địa chỉ vào bộ nhớ tạm và báo đã chép', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map<Object?, Object?>)['text']! as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await openProfileTab(tester);
    await scrollTo(tester, find.text(_privacyButton));
    await tester.tap(find.text(_privacyButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sao chép liên kết: ${PrivacyPolicy.contactLabel}'));
    await tester.pumpAndSettle();

    expect(copied, [PrivacyPolicy.issuesUrl]);
    expect(find.text('Đã sao chép liên kết.'), findsOneWidget);
  });

  testWidgets('320x568 cỡ chữ 310%: màn quyền riêng tư không tràn đến tận nút xóa dữ liệu', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await openProfileTab(tester);
    await scrollTo(tester, find.text(_privacyButton), delta: 100);
    await tester.tap(find.text(_privacyButton));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Xóa toàn bộ dữ liệu trên máy'), delta: 300);
    expect(tester.takeException(), isNull);
  });
}
