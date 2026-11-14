import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/features/home/domain/day_evaluation.dart';

enum AdviceKind { recommend, avoid, note }

final class Advice {
  const Advice({required this.kind, required this.title, required this.body});

  final AdviceKind kind;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) => other is Advice && other.kind == kind && other.title == title && other.body == body;

  @override
  int get hashCode => Object.hash(kind, title, body);

  @override
  String toString() => 'Advice($kind, $title, $body)';
}

/// Protein foods common in Vietnam, with what can rule each out. Only general food groups: Fluw makes no health claim
/// about any single food.
final class _ProteinFood {
  const _ProteinFood(this.name, this.steamedName, {this.animal = false, this.allergenTag, this.carbRich = false});

  final String name;
  final String steamedName;
  final bool animal;
  final String? allergenTag;
  final bool carbRich;
}

const List<_ProteinFood> _proteinFoods = [
  _ProteinFood('ức gà', 'ức gà luộc', animal: true),
  _ProteinFood('cá', 'cá hấp', animal: true, allergenTag: 'en:fish'),
  _ProteinFood('trứng', 'trứng luộc', animal: true, allergenTag: 'en:eggs'),
  _ProteinFood('đậu phụ', 'đậu phụ hấp', allergenTag: 'en:soybeans'),
  _ProteinFood('tôm', 'tôm hấp', animal: true, allergenTag: 'en:crustaceans'),
  _ProteinFood('sữa chua không đường', 'sữa chua không đường', animal: true, allergenTag: 'en:milk'),
  _ProteinFood('đậu lăng, đậu xanh', 'đậu lăng, đậu xanh luộc', carbRich: true),
  _ProteinFood('hạnh nhân, óc chó', 'hạnh nhân, óc chó', allergenTag: 'en:nuts'),
];

const String _readLabels = 'Luôn đọc thành phần trên nhãn: dữ liệu dị ứng của sản phẩm có thể thiếu.';

/// Rule-based suggestions from the profile and what was logged today. Calories only show up as "over" or as what is
/// left in the evening; nothing here replaces medical advice, which the screen says.
List<Advice> adviceFor({
  required PersonalLimits limits,
  required NutrientTotals today,
  required int entryCount,
  required DateTime now,
}) {
  switch (limits.profileStatus) {
    case ProfileStatus.loading:
      return const [];
    case ProfileStatus.none:
      return const [
        Advice(
          kind: AdviceKind.note,
          title: 'Thiết lập hồ sơ để nhận gợi ý',
          body: 'Fluw cần chiều cao, cân nặng, mục tiêu và bệnh nền để tính chỉ tiêu và gợi ý món phù hợp với bạn.',
        ),
      ];
    case ProfileStatus.unreadable:
      return const [
        Advice(
          kind: AdviceKind.note,
          title: 'Không đọc được hồ sơ',
          body: 'Hãy mở Hồ Sơ để nhập lại. Tới lúc đó Fluw chưa gợi ý và chưa cảnh báo dị ứng theo hồ sơ.',
        ),
      ];
    case ProfileStatus.loaded:
      break;
  }

  final allergenNames = {
    ...limits.severeAllergenTags,
    ...limits.mildAllergenTags,
  }.map((tag) => limits.allergenNames[tag] ?? tag).toList();
  final kcalTarget = limits.dailyKcal;
  final proteinMin = limits.proteinMinG;
  final kcal = today[Nutrient.energyKcal].knownSum ?? 0;
  final protein = today[Nutrient.proteinG].knownSum ?? 0;

  return [
    if (allergenNames.isNotEmpty)
      Advice(kind: AdviceKind.avoid, title: 'Tránh món có: ${allergenNames.join(', ')}', body: _readLabels),
    if (limits.watchesSugar || _isNearLimit(today[Nutrient.sugarsG].knownSum, limits.sugarsMaxG))
      Advice(
        kind: AdviceKind.avoid,
        title: 'Hạn chế đồ ngọt',
        body: _withIntake(
          today[Nutrient.sugarsG].knownSum,
          limits.sugarsMaxG,
          'g',
          'đường tổng',
          'Nên tránh trà sữa, nước ngọt có ga, bánh kẹo, chè.',
        ),
      ),
    if (limits.watchesSodium)
      Advice(
        kind: AdviceKind.avoid,
        title: 'Hạn chế muối',
        body: _withIntake(
          today[Nutrient.sodiumMg].knownSum,
          limits.sodiumMaxMg,
          'mg',
          'natri',
          'Nên bớt mì gói, nước mắm và nước chấm, dưa cà muối, đồ hộp.',
          whole: true,
        ),
      ),
    if (limits.watchesSaturatedFat)
      Advice(
        kind: AdviceKind.avoid,
        title: 'Hạn chế béo bão hòa',
        body: _withIntake(
          today[Nutrient.saturatedFatG].knownSum,
          limits.saturatedFatMaxG,
          'g',
          'béo bão hòa',
          'Nên bớt đồ chiên rán, mỡ và da động vật, thịt mỡ.',
        ),
      ),
    if (proteinMin != null && (protein * 10).round() < (proteinMin * 10).round())
      Advice(
        kind: AdviceKind.recommend,
        title: 'Bổ sung protein (đạm)',
        body: _proteinBody(limits, missing: proteinMin - protein, min: proteinMin),
      ),
    if (kcalTarget != null && (kcal / kcalTarget * 100).round() > 100 + calorieToleranceShare * 100)
      Advice(
        kind: AdviceKind.note,
        title: 'Đã vượt mục tiêu calo',
        body:
            'Hơn mục tiêu khoảng ${formatWhole(kcal - kcalTarget)} kcal. Nếu còn đói, ưu tiên rau xanh, canh rau, '
            'nước lọc.',
      )
    else if (kcalTarget != null && entryCount > 0 && now.hour >= 18 && kcalTarget - kcal >= 300)
      Advice(
        kind: AdviceKind.note,
        title: 'Còn khoảng ${formatWhole(kcalTarget - kcal)} kcal hôm nay',
        body: 'Nếu chưa ăn tối, đừng bỏ bữa: một bữa vừa phải giúp bạn gần mục tiêu hơn.',
      ),
    if (kcalTarget == null && proteinMin != null)
      const Advice(
        kind: AdviceKind.note,
        title: 'Dưới 18 tuổi',
        body: 'Fluw không tính calo cho người dưới 18 tuổi. Hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng.',
      ),
    if (kcalTarget == null && proteinMin == null)
      const Advice(
        kind: AdviceKind.note,
        title: 'Chưa tính được chỉ tiêu',
        body: 'Hãy kiểm tra lại hồ sơ để Fluw tính được chỉ tiêu mỗi ngày.',
      ),
  ];
}

bool _isNearLimit(double? eaten, double? max) => eaten != null && max != null && eaten >= max * 0.8;

String _withIntake(double? eaten, double? max, String unit, String nutrient, String tip, {bool whole = false}) {
  String format(double value) => '${whole ? formatWhole(value) : formatDecimal(value)} $unit';
  if (max == null) {
    return tip;
  }
  final intake = eaten == null ? 'Hôm nay chưa có dữ liệu $nutrient' : 'Hôm nay đã nạp ${format(eaten)} $nutrient';
  final over = eaten != null && (eaten / max * 100).round() > 100 ? ' Đã vượt giới hạn.' : '';
  return '$intake / tối đa ${format(max)}.$over $tip';
}

String _proteinBody(PersonalLimits limits, {required double missing, required double min}) {
  final allergens = {...limits.severeAllergenTags, ...limits.mildAllergenTags};
  final allowed = [
    for (final food in _proteinFoods)
      if (!(limits.avoidsAnimalProducts && food.animal) &&
          !(limits.limitsCarbohydrates && food.carbRich) &&
          !allergens.contains(food.allergenTag))
        food,
  ];
  bool isNut(_ProteinFood food) => food.allergenTag == 'en:nuts';
  // List.sort is not stable, so nuts are moved to the front by filtering instead.
  final foods = limits.likesNuts ? [...allowed.where(isNut), ...allowed.where((food) => !isNut(food))] : allowed;
  final examples = foods.take(4).map((food) => limits.prefersSteamedOrBoiled ? food.steamedName : food.name);
  final head = 'Còn thiếu khoảng ${formatDecimal(missing)} g để đạt mức tối thiểu ${formatDecimal(min)} g.';
  return examples.isEmpty ? head : '$head Gợi ý: ${examples.join('; ')}.';
}
