import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/features/reminders/domain/reminder_time.dart';

enum ReminderMoment {
  /// 00:00–05:59, for a late snack. 00:00 still belongs to the day before, so no day totals.
  night,
  morning,
  afternoon,

  /// The last reminder of the day sums the day up.
  evening;

  static ReminderMoment of(ReminderTime time) => switch (time.hour) {
    < 6 => ReminderMoment.night,
    < 12 => ReminderMoment.morning,
    < 19 => ReminderMoment.afternoon,
    _ => ReminderMoment.evening,
  };
}

final class ReminderMessage {
  const ReminderMessage({required this.title, required this.body, required this.showsIntake});

  final String title;
  final String body;

  /// The text says what was eaten, and a sugar line hints at diabetes: such texts stay off secure lock screens.
  final bool showsIntake;

  @override
  bool operator ==(Object other) =>
      other is ReminderMessage && other.title == title && other.body == body && other.showsIntake == showsIntake;

  @override
  int get hashCode => Object.hash(title, body, showsIntake);

  @override
  String toString() => 'ReminderMessage($title, $body, showsIntake: $showsIntake)';
}

/// What was logged so far on the day of the reminder.
final class DayIntake {
  const DayIntake({required this.totals, required this.entryCount, required this.unreadableCount});

  final NutrientTotals totals;
  final int entryCount;

  /// Diary rows that could not be read: not in [totals], and the text says so.
  final int unreadableCount;
}

/// [intake] is null for later days, whose meals are not known when the reminder is scheduled: those get a plain
/// "log your meal" text. Numbers only count foods that have them, and the text says when some lack data.
ReminderMessage reminderMessage({
  required ReminderMoment moment,
  required DayIntake? intake,
  required PersonalLimits limits,
}) {
  final title = moment == ReminderMoment.evening ? 'Tổng kết hôm nay' : 'Fluw nhắc ghi bữa ăn';
  ReminderMessage plain(String body) => ReminderMessage(title: title, body: body, showsIntake: false);
  if (intake == null || moment == ReminderMoment.night) {
    return plain(switch (moment) {
      ReminderMoment.night => 'Nếu bạn ăn khuya, nhớ ghi món vào Nhật ký.',
      ReminderMoment.morning => 'Ghi bữa sáng vào Nhật ký để Fluw tính đúng chỉ tiêu hôm nay.',
      ReminderMoment.afternoon => 'Đừng quên ghi bữa trưa và các món ăn vặt vào Nhật ký.',
      ReminderMoment.evening => 'Ghi nốt bữa tối để xem đánh giá cuối ngày.',
    });
  }
  if (intake.entryCount == 0) {
    if (intake.unreadableCount > 0) {
      return plain('Có ${intake.unreadableCount} món hôm nay không đọc được. Mở Nhật ký để xem lại.');
    }
    return plain(switch (moment) {
      ReminderMoment.morning => 'Bạn đã ăn sáng chưa? Ghi vào Nhật ký để Fluw tính đúng chỉ tiêu hôm nay.',
      ReminderMoment.afternoon => 'Hôm nay bạn chưa ghi món nào. Ghi lại các bữa để Fluw tính đúng.',
      ReminderMoment.evening || ReminderMoment.night => 'Hôm nay bạn chưa ghi món nào vào Nhật ký.',
    });
  }

  final totals = intake.totals;
  final kcal = totals[Nutrient.energyKcal].knownSum;
  final protein = totals[Nutrient.proteinG].knownSum;
  final sugars = totals[Nutrient.sugarsG].knownSum;
  String amount(double? value, double? target, String unit, {bool whole = false}) {
    String format(double number) => whole ? formatWhole(number) : formatDecimal(number);
    final eaten = value == null ? 'chưa có dữ liệu' : format(value);
    return target == null ? (value == null ? eaten : '$eaten $unit') : '$eaten / ${format(target)} $unit';
  }

  final parts = [
    'Năng lượng ${amount(kcal, limits.dailyKcal, 'kcal', whole: true)}',
    'protein ${amount(protein, limits.proteinMinG, 'g')}',
    if (limits.watchesSugar) 'đường ${amount(sugars, limits.sugarsMaxG, 'g')}',
  ];
  final proteinMin = limits.proteinMinG;
  // Only when protein is known for every food: with gaps the real amount may already be enough.
  final proteinShort =
      proteinMin != null &&
      protein != null &&
      totals[Nutrient.proteinG].isComplete &&
      intake.unreadableCount == 0 &&
      (protein * 10).round() < (proteinMin * 10).round();
  final missing = [
    Nutrient.energyKcal,
    Nutrient.proteinG,
    if (limits.watchesSugar) Nutrient.sugarsG,
  ].any((nutrient) => !totals[nutrient].isComplete);

  return ReminderMessage(
    title: title,
    body: [
      '${moment == ReminderMoment.evening ? 'Hôm nay' : 'Đến giờ này'}: ${parts.join(', ')}.',
      if (missing) 'Một số món thiếu số liệu.',
      if (intake.unreadableCount > 0) '${intake.unreadableCount} món không đọc được nên chưa tính.',
      if (proteinShort && moment != ReminderMoment.evening) 'Bữa tới nên có món giàu protein.',
    ].join(' '),
    showsIntake: true,
  );
}
