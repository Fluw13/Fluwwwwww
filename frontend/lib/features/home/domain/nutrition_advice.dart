import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/fluw_thresholds.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';

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
  const _ProteinFood(
    this.name,
    this.steamedName, {
    this.animal = false,
    this.allergenTags = const {},
    this.carbRich = false,
    this.isNut = false,
  });

  final String name;
  final String steamedName;
  final bool animal;
  final Set<String> allergenTags;
  final bool carbRich;
  final bool isNut;
}

const List<_ProteinFood> _proteinFoods = [
  _ProteinFood('ức gà', 'ức gà luộc', animal: true),
  _ProteinFood('cá', 'cá hấp', animal: true, allergenTags: {'en:fish'}),
  _ProteinFood('trứng', 'trứng luộc', animal: true, allergenTags: {'en:eggs'}),
  _ProteinFood('đậu phụ', 'đậu phụ hấp', allergenTags: {'en:soybeans'}),
  _ProteinFood('tôm', 'tôm hấp', animal: true, allergenTags: {'en:crustaceans'}),
  _ProteinFood('sữa chua không đường', 'sữa chua không đường', animal: true, allergenTags: {'en:milk'}),
  _ProteinFood('đậu lăng, đậu xanh', 'đậu lăng, đậu xanh luộc', carbRich: true),
  // Left out for a peanut allergy too: many people allergic to peanuts also react to tree nuts.
  _ProteinFood('hạnh nhân, óc chó', 'hạnh nhân, óc chó', allergenTags: {'en:nuts', 'en:peanuts'}, isNut: true),
];

const String _readLabels = 'Luôn đọc thành phần trên nhãn: dữ liệu dị ứng của sản phẩm có thể thiếu.';

/// Rule-based suggestions from the profile and what was logged today. [today] is null while the diary is loading or
/// could not be read: then only the advice that does not depend on what was eaten is given. A number missing from a
/// food is never taken as 0. Nothing here replaces medical advice, which the screen says.
List<Advice> adviceFor({
  required PersonalLimits limits,
  required NutrientTotals? today,
  required int entryCount,
  required int hour,
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
          body: 'Hãy mở Hồ Sơ để xem lại. Tới lúc đó Fluw chưa gợi ý và chưa cảnh báo dị ứng theo hồ sơ.',
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
  final kcal = today?[Nutrient.energyKcal];
  final kcalEaten = kcal?.knownSum;
  final protein = today?[Nutrient.proteinG];
  final proteinEaten = protein?.knownSum;
  final sugars = today?[Nutrient.sugarsG];
  final sodium = today?[Nutrient.sodiumMg];

  return [
    if (allergenNames.isNotEmpty)
      Advice(kind: AdviceKind.avoid, title: 'Tránh món có: ${allergenNames.join(', ')}', body: _readLabels),
    if (limits.watchesSugar || _isNearLimit(sugars?.knownSum, limits.sugarsMaxG))
      Advice(
        kind: AdviceKind.avoid,
        title: 'Hạn chế đồ ngọt',
        body: _withIntake(
          Nutrient.sugarsG,
          today == null ? null : sugars,
          limits.sugarsMaxG,
          'Nên tránh trà sữa, nước ngọt có ga, bánh kẹo, chè.',
        ),
      ),
    // Every adult has the sodium limit; high blood pressure gets the advice every day.
    if (limits.watchesSodium || _isNearLimit(sodium?.knownSum, limits.sodiumMaxMg))
      Advice(
        kind: AdviceKind.avoid,
        title: 'Hạn chế muối',
        body: _withIntake(
          Nutrient.sodiumMg,
          sodium,
          limits.sodiumMaxMg,
          'Nên bớt mì gói, nước mắm và nước chấm, dưa cà muối, đồ hộp.',
        ),
      ),
    if (limits.watchesSaturatedFat)
      Advice(
        kind: AdviceKind.avoid,
        title: 'Hạn chế béo bão hòa',
        body: _withIntake(
          Nutrient.saturatedFatG,
          today?[Nutrient.saturatedFatG],
          limits.saturatedFatMaxG,
          'Nên bớt đồ chiên rán, mỡ và da động vật, thịt mỡ.',
        ),
      ),
    if (proteinMin != null &&
        proteinEaten != null &&
        isBelowAsShown(Nutrient.proteinG, amount: proteinEaten, target: proteinMin))
      Advice(
        kind: AdviceKind.recommend,
        title: 'Bổ sung protein (đạm)',
        body: _proteinBody(
          limits,
          missing: proteinMin - proteinEaten,
          min: proteinMin,
          isComplete: protein!.isComplete,
        ),
      ),
    // Over is certain even with gaps, since the known total is the least that was eaten.
    if (kcalTarget != null && kcalEaten != null)
      if (isOverAsShown(Nutrient.energyKcal, amount: kcalEaten, target: kcalTarget * (1 + calorieToleranceShare)))
        Advice(
          kind: AdviceKind.note,
          title: 'Đã vượt mục tiêu calo',
          body:
              'Hơn mục tiêu ít nhất ${formatWhole(kcalEaten - kcalTarget)} kcal. Nếu còn đói, ưu tiên rau xanh, '
              'canh rau, nước lọc.',
        )
      // What is left is only known when every food has calories; a partial total would overstate it.
      else if (entryCount > 0 &&
          kcal!.isComplete &&
          hour >= eveningStartHour &&
          kcalTarget - kcalEaten >= eveningKcalLeft)
        Advice(
          kind: AdviceKind.note,
          title: 'Còn khoảng ${formatWhole(kcalTarget - kcalEaten)} kcal hôm nay',
          body: 'Nếu chưa ăn tối, đừng bỏ bữa: một bữa vừa phải giúp bạn gần mục tiêu hơn.',
        ),
    ...switch (limits.targetsKind) {
      TargetsKind.belowMinimumAge => const [
        Advice(
          kind: AdviceKind.note,
          title: 'Fluw dành cho người từ 18 tuổi',
          body: 'Hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng về lượng ăn phù hợp.',
        ),
      ],
      TargetsKind.pregnancyOrBreastfeeding => const [
        Advice(
          kind: AdviceKind.note,
          title: 'Mang thai hoặc cho con bú',
          body:
              'Nhu cầu năng lượng và đạm khi mang thai hoặc cho con bú khác người thường. '
              'Hãy hỏi bác sĩ hoặc chuyên gia dinh dưỡng.',
        ),
      ],
      TargetsKind.invalid => const [
        Advice(
          kind: AdviceKind.note,
          title: 'Chưa tính được chỉ tiêu',
          body: 'Hồ sơ còn thiếu hoặc có số chưa hợp lệ. Hãy mở Hồ Sơ để cập nhật.',
        ),
      ],
      TargetsKind.adult || null => const <Advice>[],
    },
  ];
}

bool _isNearLimit(double? eaten, double? max) => eaten != null && max != null && eaten >= max * nearLimitShare;

/// [nutrient] is total sugars, sodium or saturated fat. Total sugars has a suggestion, not a limit.
String _withIntake(Nutrient nutrient, NutrientTotal? eaten, double? max, String tip) {
  final unit = nutrient == Nutrient.sodiumMg ? 'mg' : 'g';
  String format(double value) => '${formatShownAmount(nutrient, value)} $unit';
  final name = switch (nutrient) {
    Nutrient.sugarsG => 'đường tổng',
    Nutrient.sodiumMg => 'natri',
    _ => 'béo bão hòa',
  };
  final isSuggestion = nutrient == Nutrient.sugarsG;
  if (max == null) {
    return tip;
  }
  final bound = isSuggestion ? 'mức gợi ý' : 'tối đa';
  final known = eaten?.knownSum;
  final String intake;
  if (eaten == null) {
    intake = isSuggestion
        ? 'Mức gợi ý hôm nay: dưới ${format(max)} $name.'
        : 'Giới hạn hôm nay: tối đa ${format(max)} $name.';
  } else if (known == null) {
    intake = 'Hôm nay chưa có dữ liệu $name / $bound ${format(max)}.';
  } else {
    final atLeast = eaten.isComplete ? '' : 'ít nhất ';
    intake = 'Hôm nay đã nạp $atLeast${format(known)} $name / $bound ${format(max)}.';
  }
  final over = known != null && isOverAsShown(nutrient, amount: known, target: max)
      ? (isSuggestion ? ' Cao hơn mức gợi ý.' : ' Đã vượt giới hạn.')
      : '';
  return '$intake$over $tip';
}

String _proteinBody(PersonalLimits limits, {required double missing, required double min, required bool isComplete}) {
  final allergens = {...limits.severeAllergenTags, ...limits.mildAllergenTags};
  final allowed = [
    for (final food in _proteinFoods)
      if (!(limits.avoidsAnimalProducts && food.animal) &&
          !(limits.limitsCarbohydrates && food.carbRich) &&
          !food.allergenTags.any(allergens.contains))
        food,
  ];
  // List.sort is not stable, so nuts are moved to the front by filtering instead.
  final foods = limits.likesNuts
      ? [...allowed.where((food) => food.isNut), ...allowed.where((food) => !food.isNut)]
      : allowed;
  final examples = foods.take(4).map((food) => limits.prefersSteamedOrBoiled ? food.steamedName : food.name);
  final head = isComplete
      ? 'Còn thiếu khoảng ${formatDecimal(missing)} g để đạt mức tối thiểu ${formatDecimal(min)} g.'
      : 'Còn thiếu tối đa khoảng ${formatDecimal(missing)} g để đạt mức tối thiểu ${formatDecimal(min)} g '
            '(một số món thiếu số liệu).';
  return examples.isEmpty ? head : '$head Gợi ý: ${examples.join('; ')}.';
}
