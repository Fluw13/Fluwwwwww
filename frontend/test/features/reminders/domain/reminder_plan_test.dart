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

PersonalLimits _limits({bool watchesSugar = false, double? sodiumMaxMg = 2000}) => PersonalLimits(
  profileStatus: ProfileStatus.loaded,
  severeAllergenTags: const {},
  mildAllergenTags: const {},
  allergenNames: const {},
  dailyKcal: 2000,
  proteinMinG: 100,
  sugarsMaxG: 50,
  saturatedFatMaxG: 20,
  sodiumMaxMg: sodiumMaxMg,
  watchesSugar: watchesSugar,
  watchesSodium: false,
  watchesSaturatedFat: false,
);

DayIntake _intake(List<Map<Nutrient, double>> foods, {int unreadable = 0}) => DayIntake(
  totals: NutrientTotals.of(foods.map(Nutrients.new)),
  entryCount: foods.length,
  unreadableCount: unreadable,
);

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
        showsIntake: true,
      ),
    );
    expect(plan[3].message.body, 'Ghi bữa sáng vào Nhật ký để Fluw tính đúng chỉ tiêu hôm nay.');
    expect(plan[3].message.showsIntake, isFalse, reason: 'lời nhắc chung được hiện trên màn khóa');
  });

  test('id nằm trong dải của nhắc bữa ăn; kho hỏng có hơn 10 giờ thì id vẫn không trùng', () {
    final many = ReminderSettings(enabled: true, times: [for (var hour = 6; hour < 18; hour++) ReminderTime(hour, 0)]);
    expect(many.times, hasLength(ReminderSettings.maxTimes));

    final plan = planReminders(
      settings: many,
      now: DateTime(2026, 11, 30, 5),
      today: today,
      todayIntake: _intake(const []),
      limits: _limits(),
    );
    final ids = plan.map((reminder) => reminder.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.every(isMealReminderId), isTrue);
    expect(isMealReminderId(mealReminderIdEnd - 1), isTrue);
    expect(isMealReminderId(mealReminderIdEnd), isFalse, reason: 'dải sau dành cho nhắc uống nước');
    expect(isMealReminderId(-1), isFalse);
  });

  test('khung theo giờ: trước 6h là khuya, trước 12h là sáng, 12h–18h59 là chiều, từ 19h là tổng kết', () {
    expect(ReminderMoment.of(const ReminderTime(0, 0)), ReminderMoment.night);
    expect(ReminderMoment.of(const ReminderTime(5, 59)), ReminderMoment.night);
    expect(ReminderMoment.of(const ReminderTime(6, 0)), ReminderMoment.morning);
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
    expect(partial.body, contains('đường tổng 3 / gợi ý 50 g'));
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

  test('natri vượt giới hạn (theo số hiện) thì nhắc, cho mọi người lớn; chưa vượt hay không có chỉ tiêu thì không', () {
    String body(double sodium, {double? sodiumMaxMg = 2000}) => reminderMessage(
      moment: ReminderMoment.evening,
      intake: _intake([
        {Nutrient.energyKcal: 1800, Nutrient.proteinG: 100, Nutrient.sodiumMg: sodium},
      ]),
      limits: _limits(sodiumMaxMg: sodiumMaxMg),
    ).body;

    expect(body(2100), contains('Natri đã vượt giới hạn 2,000 mg.'));
    expect(body(2000.4), isNot(contains('Natri')), reason: 'hiện là 2,000 mg');
    expect(body(5000, sodiumMaxMg: null), isNot(contains('Natri')));
  });

  test('theo dõi đường mà có món thiếu số đường thì nói thiếu số liệu, không hiện như tổng đủ', () {
    final foods = _intake([
      {Nutrient.energyKcal: 500, Nutrient.proteinG: 20, Nutrient.sugarsG: 3},
      {Nutrient.energyKcal: 300, Nutrient.proteinG: 10},
    ]);

    final watching = reminderMessage(
      moment: ReminderMoment.afternoon,
      intake: foods,
      limits: _limits(watchesSugar: true),
    );
    expect(watching.body, contains('đường tổng 3 / gợi ý 50 g'));
    expect(watching.body, contains('Một số món thiếu số liệu.'));

    final notWatching = reminderMessage(moment: ReminderMoment.afternoon, intake: foods, limits: _limits());
    expect(notWatching.body, isNot(contains('thiếu số liệu')), reason: 'không hiện dòng đường thì không cần nói');
  });

  test('món không đọc được: nói rõ, không bảo là chưa ghi món nào', () {
    final onlyUnreadable = reminderMessage(
      moment: ReminderMoment.evening,
      intake: _intake(const [], unreadable: 2),
      limits: _limits(),
    );
    expect(onlyUnreadable.body, 'Có 2 món hôm nay không đọc được. Mở Nhật ký để xem lại.');

    final some = reminderMessage(
      moment: ReminderMoment.afternoon,
      intake: _intake([
        {Nutrient.energyKcal: 500, Nutrient.proteinG: 20},
      ], unreadable: 1),
      limits: _limits(),
    );
    expect(some.body, contains('1 món không đọc được nên chưa tính.'));
    expect(some.body, isNot(contains('giàu protein')), reason: 'món không đọc được có thể đã đủ protein');
  });

  test('nhắc lúc khuya là lời nhắc chung, không tổng kết ngày; chỉ nhắc có số liệu mới ẩn khỏi màn khóa', () {
    final eaten = _intake([
      {Nutrient.energyKcal: 500, Nutrient.proteinG: 20},
    ]);

    final night = reminderMessage(moment: ReminderMoment.night, intake: eaten, limits: _limits());
    expect(night.body, 'Nếu bạn ăn khuya, nhớ ghi món vào Nhật ký.');
    expect(night.showsIntake, isFalse);

    expect(reminderMessage(moment: ReminderMoment.morning, intake: eaten, limits: _limits()).showsIntake, isTrue);
    expect(
      reminderMessage(moment: ReminderMoment.morning, intake: _intake(const []), limits: _limits()).showsIntake,
      isFalse,
    );
  });
}
