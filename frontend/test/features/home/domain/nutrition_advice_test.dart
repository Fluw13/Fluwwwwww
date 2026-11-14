import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/features/home/domain/nutrition_advice.dart';

PersonalLimits _limits({
  Set<String> severe = const {},
  Set<String> mild = const {},
  bool watchesSugar = false,
  bool watchesSodium = false,
  bool watchesSaturatedFat = false,
  bool vegan = false,
  bool keto = false,
  bool steamed = false,
  bool nuts = false,
  double? kcal = 2000,
  double? proteinMin = 100,
}) => PersonalLimits(
  profileStatus: ProfileStatus.loaded,
  severeAllergenTags: severe,
  mildAllergenTags: mild,
  allergenNames: const {'en:fish': 'Cá', 'en:milk': 'Sữa', 'en:eggs': 'Trứng', 'en:soybeans': 'Đậu nành'},
  dailyKcal: kcal,
  proteinMinG: proteinMin,
  sugarsMaxG: kcal == null ? null : 50,
  saturatedFatMaxG: kcal == null ? null : 20,
  sodiumMaxMg: kcal == null ? null : 2000,
  watchesSugar: watchesSugar,
  watchesSodium: watchesSodium,
  watchesSaturatedFat: watchesSaturatedFat,
  avoidsAnimalProducts: vegan,
  limitsCarbohydrates: keto,
  prefersSteamedOrBoiled: steamed,
  likesNuts: nuts,
);

NutrientTotals _today(Map<Nutrient, double> values) => NutrientTotals.of([Nutrients(values)]);

final DateTime _morning = DateTime(2026, 11, 11, 9);
final DateTime _evening = DateTime(2026, 11, 11, 20);

List<Advice> _advice(PersonalLimits limits, Map<Nutrient, double> today, {DateTime? now, int entries = 1}) =>
    adviceFor(limits: limits, today: _today(today), entryCount: entries, now: now ?? _morning);

Advice _protein(List<Advice> advice) => advice.firstWhere((item) => item.title.startsWith('Bổ sung protein'));

void main() {
  test('chưa có hồ sơ hoặc hồ sơ hỏng thì chỉ có một lời nhắc, không gợi ý theo số liệu', () {
    List<Advice> forStatus(ProfileStatus status) =>
        adviceFor(limits: PersonalLimits.empty(status), today: _today(const {}), entryCount: 0, now: _morning);

    expect(forStatus(ProfileStatus.none).single.title, 'Thiết lập hồ sơ để nhận gợi ý');
    expect(forStatus(ProfileStatus.unreadable).single.title, 'Không đọc được hồ sơ');
    expect(forStatus(ProfileStatus.loading), isEmpty);
  });

  test('thiếu protein: nói còn thiếu bao nhiêu và gợi ý nhóm thực phẩm', () {
    final advice = _protein(_advice(_limits(), {Nutrient.energyKcal: 800, Nutrient.proteinG: 40}));

    expect(advice.kind, AdviceKind.recommend);
    expect(advice.body, startsWith('Còn thiếu khoảng 60 g để đạt mức tối thiểu 100 g.'));
    expect(advice.body, contains('Gợi ý: ức gà; cá; trứng; đậu phụ.'));
  });

  test('đủ protein (theo 0,1 g) thì không gợi ý thêm', () {
    expect(
      _advice(_limits(), {Nutrient.proteinG: 99.96}).where((item) => item.title.startsWith('Bổ sung protein')),
      isEmpty,
    );
  });

  test('gợi ý protein bỏ món người dùng dị ứng (cả nặng lẫn nhẹ) và theo chế độ ăn', () {
    final allergic = _protein(_advice(_limits(severe: {'en:fish'}, mild: {'en:eggs'}), {Nutrient.proteinG: 0}));
    expect(allergic.body, isNot(contains('cá')));
    expect(allergic.body, isNot(contains('trứng')));

    final vegan = _protein(_advice(_limits(vegan: true, severe: {'en:soybeans'}), {Nutrient.proteinG: 0}));
    expect(vegan.body, contains('Gợi ý: đậu lăng, đậu xanh; hạnh nhân, óc chó.'));

    final keto = _protein(_advice(_limits(vegan: true, keto: true), {Nutrient.proteinG: 0}));
    expect(keto.body, isNot(contains('đậu lăng')));

    final steamedNuts = _protein(_advice(_limits(steamed: true, nuts: true), {Nutrient.proteinG: 0}));
    expect(steamedNuts.body, contains('Gợi ý: hạnh nhân, óc chó; ức gà luộc; cá hấp; trứng luộc.'));
  });

  test('không còn món nào hợp thì chỉ nói số còn thiếu, không bịa gợi ý', () {
    final advice = _protein(
      _advice(_limits(vegan: true, keto: true, severe: {'en:soybeans', 'en:nuts'}), {Nutrient.proteinG: 10}),
    );

    expect(advice.body, 'Còn thiếu khoảng 90 g để đạt mức tối thiểu 100 g.');
  });

  test('dị ứng: nhắc tránh theo tên người dùng đặt và đọc nhãn', () {
    final advice = _advice(_limits(severe: {'en:fish'}, mild: {'en:milk'}), const {}).first;

    expect(advice.kind, AdviceKind.avoid);
    expect(advice.title, 'Tránh món có: Cá, Sữa');
    expect(advice.body, contains('đọc thành phần trên nhãn'));
  });

  test('tiểu đường/giảm ngọt: luôn nhắc hạn chế đồ ngọt kèm số đã nạp; không theo dõi thì nhắc khi gần giới hạn', () {
    final watched = _advice(_limits(watchesSugar: true), {Nutrient.sugarsG: 12});
    expect(
      watched.firstWhere((item) => item.title == 'Hạn chế đồ ngọt').body,
      'Hôm nay đã nạp 12 g đường tổng / tối đa 50 g. Nên tránh trà sữa, nước ngọt có ga, bánh kẹo, chè.',
    );

    expect(_advice(_limits(), {Nutrient.sugarsG: 39}).where((item) => item.title == 'Hạn chế đồ ngọt'), isEmpty);
    expect(
      _advice(_limits(), {Nutrient.sugarsG: 55}).firstWhere((item) => item.title == 'Hạn chế đồ ngọt').body,
      contains('Đã vượt giới hạn.'),
    );
  });

  test('huyết áp cao và mỡ máu cao có lời nhắc riêng; thiếu số liệu thì nói rõ', () {
    final advice = _advice(_limits(watchesSodium: true, watchesSaturatedFat: true), {Nutrient.sodiumMg: 1250.4});

    expect(
      advice.firstWhere((item) => item.title == 'Hạn chế muối').body,
      startsWith('Hôm nay đã nạp 1,250 mg natri / tối đa 2,000 mg.'),
    );
    expect(
      advice.firstWhere((item) => item.title == 'Hạn chế béo bão hòa').body,
      startsWith('Hôm nay chưa có dữ liệu béo bão hòa / tối đa 20 g.'),
    );
  });

  test('calo: vượt hơn 10% thì nhắc; buổi tối còn nhiều thì nhắc đừng bỏ bữa; buổi sáng thì không', () {
    expect(_advice(_limits(), {Nutrient.energyKcal: 2300, Nutrient.proteinG: 120}).last.title, 'Đã vượt mục tiêu calo');
    expect(
      _advice(_limits(), {Nutrient.energyKcal: 1200, Nutrient.proteinG: 120}, now: _evening).last.title,
      'Còn khoảng 800 kcal hôm nay',
    );
    expect(_advice(_limits(), {Nutrient.energyKcal: 1200, Nutrient.proteinG: 120}), isEmpty);
    expect(
      _advice(_limits(), {Nutrient.energyKcal: 0, Nutrient.proteinG: 120}, now: _evening, entries: 0),
      isEmpty,
      reason: 'chưa ghi món nào thì không đoán là chưa ăn',
    );
  });

  test('dưới 18 tuổi: không nói về calo, nhắc hỏi chuyên gia', () {
    final advice = _advice(_limits(kcal: null, proteinMin: 45), {Nutrient.proteinG: 50});

    expect(advice.single.title, 'Dưới 18 tuổi');
  });
}
