import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/erase_all_data.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/privacy/health_data_consent.dart';
import 'package:fluw/core/settings/theme_mode_controller.dart';
import 'package:fluw/features/privacy/presentation/privacy_screen.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/weight_entry.dart';
import 'package:fluw/features/reminders/data/reminder_settings_controller.dart';
import 'package:fluw/features/reminders/data/reminder_settings_storage.dart';
import 'package:fluw/features/scan/data/photo_consent_storage.dart';
import 'package:fluw/features/search/presentation/recent_searches_controller.dart';

import '../features/profile/domain/profile_fixture.dart';
import '../helpers/load_app_fonts.dart';
import '../helpers/pump_fluw_app.dart';
import '../helpers/scroll_to.dart';

const String _eraseButton = 'Xóa toàn bộ dữ liệu trên máy';

/// A user with every kind of data: settings, reminders on, consents given.
const Map<String, Object> _settings = {
  'theme_mode': 'dark',
  ReminderSettingsStorage.enabledKey: true,
  ReminderSettingsStorage.timesKey: ['10:00', '17:00', '22:00'],
  'recent_searches': ['phở', 'sữa chua'],
  PhotoConsentStorage.key: PhotoConsentStorage.currentVersion,
};

void main() {
  AppDatabase databaseOf(WidgetTester tester) => appContainer(tester).read(appDatabaseProvider);

  /// One write per runAsync: the app's own reload runs in fake time and would deadlock a second real-time write.
  Future<void> storeEverything(WidgetTester tester) async {
    final profile = buildProfile(
      conditions: {HealthCondition.diabetes},
      dietary: DietaryPreferences(
        allergies: {Allergen.peanuts: AllergySeverity.severe},
        allergyNote: null,
        dietStyle: DietStyle.keto,
        preferences: {FoodPreference.likesNuts},
      ),
    );
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(profile));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () =>
          appContainer(tester).read(weightLogRepositoryProvider).record(WeightEntry(date: appTestToday, weightKg: 70)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => databaseOf(tester)
          .into(databaseOf(tester).noteEntries)
          .insert(
            NoteEntriesCompanion.insert(
              id: 'pho',
              name: 'Phở bò',
              unit: 'g',
              quantity: 350,
              eatenAtUtcMs: DateTime(appTestToday.year, appTestToday.month, appTestToday.day, 8).millisecondsSinceEpoch,
            ),
          ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => databaseOf(tester)
          .into(databaseOf(tester).customProducts)
          .insert(
            CustomProductsCompanion.insert(
              id: 'latte',
              name: 'Trà sữa latte',
              unit: 'ml',
              labelPerServing: false,
              updatedAtUtcMs: 0,
            ),
          ),
    );
    await tester.pumpAndSettle();
  }

  Future<Map<String, int>> rowCounts(WidgetTester tester) async {
    final database = databaseOf(tester);
    final counts = <String, int>{};
    await tester.runAsync(() async {
      for (final table in database.allTables) {
        counts[table.actualTableName] = (await database.select(table).get()).length;
      }
    });
    return counts;
  }

  Future<void> tapErase(WidgetTester tester) async {
    await scrollTo(tester, find.text(_eraseButton));
    await tester.tap(find.text(_eraseButton));
    await tester.pumpAndSettle();
  }

  testWidgets('Hồ Sơ → Xóa toàn bộ: hỏi trước, xóa mọi bảng, cài đặt, đồng ý, hủy nhắc; giữ Sáng/Tối', (tester) async {
    final preferences = await pumpFluwApp(tester, storedSettings: _settings);
    await storeEverything(tester);
    expect((await rowCounts(tester)).values, everyElement(greaterThan(0)), reason: 'mỗi bảng có dữ liệu trước khi xóa');
    expect(appNotifications(tester).current, isNotEmpty);
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();

    await tapErase(tester);
    expect(find.text('Xóa toàn bộ dữ liệu trên máy?'), findsOneWidget);
    expect(find.textContaining('Không khôi phục được.'), findsOneWidget);
    expect(find.textContaining('Bản sao lưu của Google/iCloud'), findsOneWidget);
    await tester.tap(find.text('Xóa toàn bộ'));
    await tester.pumpAndSettle();

    expect(find.text('Đã xóa toàn bộ dữ liệu trên máy.'), findsOneWidget);
    expect(find.text('Chưa có hồ sơ sức khỏe'), findsOneWidget);
    expect((await rowCounts(tester)).values, everyElement(0));
    expect(preferences.getKeys(), {'theme_mode'});
    expect(appContainer(tester).read(themeModeProvider), ThemeMode.dark);
    expect(appNotifications(tester).current, isEmpty);
    expect(appContainer(tester).read(reminderSettingsProvider).enabled, isFalse);
    expect(appContainer(tester).read(recentSearchesProvider), isEmpty);
    expect(appContainer(tester).read(healthDataConsentStorageProvider).hasConsent, isFalse);
  });

  testWidgets('bấm Hủy thì không xóa gì', (tester) async {
    final preferences = await pumpFluwApp(tester, storedSettings: _settings);
    await storeEverything(tester);
    final keys = preferences.getKeys();
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();

    await tapErase(tester);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect((await rowCounts(tester)).values, everyElement(greaterThan(0)));
    expect(preferences.getKeys(), keys);
    expect(find.text('Đã xóa toàn bộ dữ liệu trên máy.'), findsNothing);
  });

  testWidgets('nhắc đã tắt trong app vẫn được hủy trên máy (lần hủy trước có thể đã lỗi)', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await tester.pumpAndSettle();
    final notifications = appNotifications(tester);
    final sentBefore = notifications.scheduled.length;
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();

    await tapErase(tester);
    await tester.tap(find.text('Xóa toàn bộ'));
    await tester.pumpAndSettle();

    expect(notifications.scheduled.length, greaterThan(sentBefore));
    expect(notifications.current, isEmpty);
  });

  testWidgets('xóa từ màn quyền riêng tư (chưa có hồ sơ, còn Nhật ký): đóng màn, về tab Hồ Sơ', (tester) async {
    final preferences = await pumpFluwApp(tester, storedSettings: _settings);
    await tester.runAsync(
      () =>
          databaseOf(tester)
              .into(databaseOf(tester).noteEntries)
              .insert(NoteEntriesCompanion.insert(id: 'a', name: 'Chuối', unit: 'g', quantity: 100, eatenAtUtcMs: 0)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Quyền riêng tư và điều khoản'));
    await tester.tap(find.text('Quyền riêng tư và điều khoản'));
    await tester.pumpAndSettle();

    await tapErase(tester);
    await tester.tap(find.text('Xóa toàn bộ'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyScreen), findsNothing);
    expect(find.text('Chưa có hồ sơ sức khỏe'), findsOneWidget);
    expect(find.text('Đã xóa toàn bộ dữ liệu trên máy.'), findsOneWidget);
    expect((await rowCounts(tester)).values, everyElement(0));
    expect(preferences.getKeys(), {'theme_mode'});
  });

  testWidgets('xóa lỗi thì báo chưa xóa hết, ở lại để thử lại', (tester) async {
    await pumpFluwApp(
      tester,
      overrides: [eraseAllDataProvider.overrideWithValue(() async => throw StateError('kho cài đặt hỏng'))],
    );
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Quyền riêng tư và điều khoản'));
    await tester.tap(find.text('Quyền riêng tư và điều khoản'));
    await tester.pumpAndSettle();

    await tapErase(tester);
    await tester.tap(find.text('Xóa toàn bộ'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isStateError, reason: 'lỗi được báo cho FlutterError để dễ tìm nguyên nhân');
    expect(find.textContaining('Chưa xóa được hết dữ liệu.'), findsOneWidget);
    expect(find.byType(PrivacyScreen), findsOneWidget);
  });

  testWidgets('320x568 cỡ chữ 310%: nút xóa và hộp xác nhận không tràn', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadAppFonts();
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text(_eraseButton), delta: 300);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(_eraseButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(AlertDialog), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Xóa toàn bộ').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
