import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/privacy/health_data_consent.dart';
import 'package:fluw/features/privacy/presentation/privacy_policy_text.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../../../helpers/scroll_to.dart';
import '../domain/profile_fixture.dart';

const String _consentTitle = 'Đồng ý lưu thông tin sức khỏe';

void main() {
  ProfileRepository repositoryOf(WidgetTester tester) => appContainer(tester).read(profileRepositoryProvider);

  Future<SharedPreferences> openNewProfileForm(WidgetTester tester) async {
    final preferences = await pumpFluwApp(tester, healthDataConsent: false);
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thiết lập hồ sơ').last);
    await tester.pumpAndSettle();
    return preferences;
  }

  /// A complete adult profile that keeps its weight, so no weekly speed is asked.
  Future<void> fillProfile(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextField, 'Tên gọi (không bắt buộc)'), 'Linh');
    await tester.tap(find.text('Chọn ngày sinh'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '04/03/1998');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nam'));
    await tester.enterText(find.widgetWithText(TextField, 'Chiều cao'), '165');
    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng'), '58');
    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng mong muốn'), '58');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Mức vận động hằng ngày'));
    await tester.tap(find.text('Mức vận động hằng ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoạt động nhẹ').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Hình thức tập'));
    await tester.tap(find.text('Hình thức tập'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Không tập thường xuyên').last);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
  }

  testWidgets('lần lưu đầu hỏi đồng ý; "Để sau" không lưu gì và giữ nguyên những gì đã nhập', (tester) async {
    final preferences = await openNewProfileForm(tester);
    await fillProfile(tester);

    await tapSave(tester);
    expect(find.text(_consentTitle), findsOneWidget);
    expect(find.textContaining('mang thai hoặc cho con bú'), findsOneWidget);
    expect(find.textContaining('không gửi chúng lên máy chủ'), findsOneWidget);
    expect(find.text('Fluw chỉ dành cho người từ 18 tuổi.'), findsOneWidget);
    expect(find.textContaining('16 tuổi'), findsNothing);

    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa lưu hồ sơ. Fluw chỉ lưu thông tin sức khỏe khi bạn đồng ý.'), findsOneWidget);
    expect(await tester.runAsync(repositoryOf(tester).load), isA<NoProfile>());
    expect(preferences.containsKey(HealthDataConsentStorage.versionKey), isFalse);
    await scrollTo(tester, find.widgetWithText(TextField, 'Linh'), delta: -200);
    expect(find.widgetWithText(TextField, 'Linh'), findsOneWidget, reason: 'bản nháp còn nguyên');
  });

  testWidgets('đồng ý thì lưu hồ sơ kèm phiên bản chữ và thời điểm; lần lưu sau không hỏi lại', (tester) async {
    final preferences = await openNewProfileForm(tester);
    await fillProfile(tester);

    await tapSave(tester);
    await tester.tap(find.text('Tôi đồng ý'));
    await tester.pumpAndSettle();

    expect(find.text('Đã lưu hồ sơ.'), findsOneWidget);
    expect(((await tester.runAsync(repositoryOf(tester).load)) as LoadedProfile).profile.displayName, 'Linh');
    expect(preferences.getInt(HealthDataConsentStorage.versionKey), HealthDataConsentStorage.currentVersion);
    expect(
      preferences.getString(HealthDataConsentStorage.agreedAtKey),
      DateTime(appTestToday.year, appTestToday.month, appTestToday.day, appTestHour).toUtc().toIso8601String(),
    );

    await scrollTo(tester, find.text('Cập nhật hồ sơ'));
    await tester.tap(find.text('Cập nhật hồ sơ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Chiều cao'), '166');
    await tapSave(tester);

    expect(find.text(_consentTitle), findsNothing);
    expect(((await tester.runAsync(repositoryOf(tester).load)) as LoadedProfile).profile.heightCm, 166);
  });

  testWidgets('hồ sơ lưu trước khi có bước đồng ý: lần sửa tiếp theo cũng hỏi, không đồng ý thì giữ bản cũ', (
    tester,
  ) async {
    await pumpFluwApp(tester, healthDataConsent: false);
    await tester.runAsync(() => repositoryOf(tester).save(buildProfile()));
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Cập nhật hồ sơ'));
    await tester.tap(find.text('Cập nhật hồ sơ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng'), '72');

    await tapSave(tester);
    expect(find.text(_consentTitle), findsOneWidget);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();

    expect(((await tester.runAsync(repositoryOf(tester).load)) as LoadedProfile).profile, buildProfile());
  });

  testWidgets('"Đọc chính sách quyền riêng tư" mở màn chính sách; quay lại thì bản nháp còn, chưa lưu gì', (
    tester,
  ) async {
    await openNewProfileForm(tester);
    await fillProfile(tester);
    await tapSave(tester);

    await tester.tap(find.text('Đọc chính sách quyền riêng tư'));
    await tester.pumpAndSettle();
    expect(find.text(PrivacyPolicy.title), findsOneWidget);
    expect(find.text('Chưa lưu hồ sơ. Fluw chỉ lưu thông tin sức khỏe khi bạn đồng ý.'), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.widgetWithText(TextField, 'Linh'), delta: -200);
    expect(find.widgetWithText(TextField, 'Linh'), findsOneWidget);
    expect(await tester.runAsync(repositoryOf(tester).load), isA<NoProfile>());

    await tapSave(tester);
    expect(find.text(_consentTitle), findsOneWidget, reason: 'vẫn phải đồng ý trước khi lưu');
  });

  testWidgets('320x568 cỡ chữ 310%: hộp đồng ý không tràn', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await pumpFluwApp(tester, healthDataConsent: false);
    await tester.runAsync(() => repositoryOf(tester).save(buildProfile()));
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Cập nhật hồ sơ'), delta: 100);
    await tester.tap(find.text('Cập nhật hồ sơ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text(_consentTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(AlertDialog), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Tôi đồng ý').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
