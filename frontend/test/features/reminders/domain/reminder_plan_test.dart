import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/reminders/domain/reminder_message.dart';
import 'package:fluw/features/reminders/domain/reminder_plan.dart';
import 'package:fluw/features/reminders/domain/reminder_settings.dart';
import 'package:fluw/features/reminders/domain/reminder_time.dart';

PersonalLimits _limits({bool watchesSugar = false}) => PersonalLimits(
  profileStatus: ProfileStatus.loaded,
  severeAllergenTags: const {},
  mildAllergenTags: const {},
  allergenNames: const {},
  dailyKcal: 2000,
  proteinMinG: 100,
  sugarsMaxG: 50,
  saturatedFatMaxG: 20,
  sodiumMaxMg: 2000,
  watchesSugar: watchesSugar,
  watchesSodium: false,
  watchesSaturatedFat: false,
);

DayIntake _intake(List<Map<Nutrient, double>> foods) =>
    DayIntake(totals: NutrientTotals.of(foods.map(Nutrients.new)), entryCount: foods.length);

void main() {
  final today = CalendarDate(2026, 11, 30);
  final enabled = ReminderSettings(enabled: true, times: ReminderSettings.defaultTimes);

  test('tắt nhắc nhở thì không hẹn gì', () {
    expect(
      planReminders(
        settings: ReminderSettings.defaults,
        now: DateTime(2026, 11, 30, 8),
        today: today,
        todayIntake: _intake(const []),
        limits: _limits(),
      ),
      isEmpty,
    );
  });

  test('hẹn 7 ngày, bỏ giờ đã qua, id cố định theo ngày và khung, qua được sang tháng mới', () {
    final plan = planReminders(
      settings: enabled,
      now: DateTime(2026, 11, 30, 12),
      today: today,
      todayIntake: _intake(const []),
      limits: _limits(),
    );

    expect(plan, hasLength(7 * 3 - 1), reason: '10:00 hôm nay đã qua');
    expect(plan.first.at, DateTime(2026, 11, 30, 17));
    expect(plan.first.id, 1);
    expect(plan[2].at, DateTime(2026, 12, 1, 10));
    expect(plan[2].id, 10);
    expect(plan.last.at, DateTime(2026, 12, 6, 22));
  });

  test('nhắc hôm nay nói lượng đã ghi; ngày sau là lời nhắc chung', () {
    final plan = planReminders(
      settings: enabled,
      now: DateTime(2026, 11, 30, 8),
      today: today,
      todayIntake: _intake([
        {Nutrient.energyKcal: 600, Nutrient.proteinG: 30},
      ]),
      limits: _limits(),
    );

    expect(
      plan[1].message.body,
      'Đến giờ này: Năng lượng 600 / 2,000 kcal, protein 30 / 100 g. Bữa tới nên có món giàu protein.',
    );
    expect(
      plan[2].message,
      const ReminderMessage(
        title: 'Tổng kết hôm nay',
        body: 'Hôm nay: Năng lượng 600 / 2,000 kcal, protein 30 / 100 g.',
      ),
    );
    expect(plan[3].message.body, 'Ghi bữa sáng vào Nhật ký để Fluw tính đúng chỉ tiêu hôm nay.');
  });

  test('khung theo giờ: trước 12h là sáng, 12h–18h59 là chiều, từ 19h là tổng kết', () {
    expect(ReminderMoment.of(const ReminderTime(11, 59)), ReminderMoment.morning);
    expect(ReminderMoment.of(const ReminderTime(12, 0)), ReminderMoment.afternoon);
    expect(ReminderMoment.of(const ReminderTime(18, 59)), ReminderMoment.afternoon);
    expect(ReminderMoment.of(const ReminderTime(19, 0)), ReminderMoment.evening);
  });

  test('chưa ghi món, thiếu số liệu, theo dõi đường: lời nhắc nói đúng, không coi số thiếu là 0', () {
    ReminderMessage message(ReminderMoment moment, DayIntake intake, {bool watchesSugar = false}) => reminderMessage(
      moment: moment,
      intake: intake,
      limits: _limits(watchesSugar: watchesSugar),
    );

    expect(message(ReminderMoment.morning, _intake(const [])).body, startsWith('Bạn đã ăn sáng chưa?'));
    expect(message(ReminderMoment.evening, _intake(const [])).body, 'Hôm nay bạn chưa ghi món nào vào Nhật ký.');

    final partial = message(
      ReminderMoment.afternoon,
      _intake([
        {Nutrient.energyKcal: 500, Nutrient.proteinG: 20},
        {Nutrient.sugarsG: 3},
      ]),
      watchesSugar: true,
    );
    expect(partial.body, contains('đường 3 / 50 g'));
    expect(partial.body, contains('Một số món thiếu số liệu.'));
    expect(partial.body, isNot(contains('giàu protein')), reason: 'protein chưa đủ số liệu thì không kết luận thiếu');

    final unknownKcal = message(
      ReminderMoment.evening,
      _intake([
        {Nutrient.proteinG: 20},
      ]),
    );
    expect(unknownKcal.body, contains('Năng lượng chưa có dữ liệu / 2,000 kcal'));
  });
}
