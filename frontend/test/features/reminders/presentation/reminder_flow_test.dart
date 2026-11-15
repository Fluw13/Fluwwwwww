import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/diary/note_entry.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/note/data/note_providers.dart';
import 'package:fluw/features/reminders/data/reminder_settings_storage.dart';
import 'package:fluw/features/reminders/presentation/reminder_settings_screen.dart';

import '../../../helpers/pump_fluw_app.dart';

void main() {
  Future<void> openReminders(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Nhắc nhở'));
    await tester.pumpAndSettle();
  }

  testWidgets('chuông trên header mở cài đặt nhắc nhở: mặc định tắt, giờ 10:00, 17:00, 22:00', (tester) async {
    await pumpFluwApp(tester);
    await openReminders(tester);

    expect(find.byType(ReminderSettingsScreen), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('17:00'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
    expect(appNotifications(tester).current, isEmpty, reason: 'chưa bật thì không hẹn gì');
  });

  testWidgets('bật nhắc nhở: xin quyền, lưu, hẹn 7 ngày; ghi món thì nội dung nhắc hôm nay đổi theo', (tester) async {
    final preferences = await pumpFluwApp(tester);
    await openReminders(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    final notifications = appNotifications(tester);
    expect(notifications.permissionRequests, 1);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    expect(preferences.getBool(ReminderSettingsStorage.enabledKey), isTrue);
    expect(notifications.current, hasLength(21), reason: 'lúc 09:00 thì cả 3 giờ hôm nay chưa qua');
    expect(notifications.current!.first.at, DateTime(2026, 11, 11, 10));
    expect(notifications.current!.first.message.body, startsWith('Bạn đã ăn sáng chưa?'));

    await tester.runAsync(
      () => appContainer(tester)
          .read(noteRepositoryProvider)
          .add(
            NoteEntry(
              id: 'pho',
              name: 'Phở bò',
              sourceFoodId: null,
              facts: NutritionFacts(
                per100: Nutrients(const {Nutrient.energyKcal: 120, Nutrient.proteinG: 6}),
                unit: QuantityUnit.gram,
              ),
              quantity: 500,
              eatenAt: DateTime(2026, 11, 11, 8),
            ),
          ),
    );
    await tester.pumpAndSettle();

    expect(notifications.current!.first.message.body, startsWith('Đến giờ này: Năng lượng 600 kcal, protein 30 g.'));
  });

  testWidgets('không được cấp quyền thông báo: vẫn tắt, báo cách bật trong Cài đặt', (tester) async {
    final preferences = await pumpFluwApp(tester);
    await openReminders(tester);
    appNotifications(tester).grantPermission = false;

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    expect(find.textContaining('chưa được phép gửi thông báo'), findsOneWidget);
    expect(preferences.getBool(ReminderSettingsStorage.enabledKey), isNot(isTrue));
    expect(appNotifications(tester).current, isEmpty);
  });

  testWidgets('tắt nhắc nhở thì hủy hết lịch đã hẹn; giờ đã đổi thì có nút về mặc định', (tester) async {
    await pumpFluwApp(
      tester,
      storedSettings: {
        ReminderSettingsStorage.enabledKey: true,
        ReminderSettingsStorage.timesKey: ['09:30', '17:00', '22:00'],
      },
    );
    await openReminders(tester);
    final notifications = appNotifications(tester);
    expect(notifications.current!.first.at, DateTime(2026, 11, 11, 9, 30));

    await tester.tap(find.text('Về giờ mặc định 10:00, 17:00, 22:00'));
    await tester.pumpAndSettle();
    expect(find.text('10:00'), findsOneWidget);
    expect(notifications.current!.first.at, DateTime(2026, 11, 11, 10));

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(notifications.current, isEmpty);
  });
}
