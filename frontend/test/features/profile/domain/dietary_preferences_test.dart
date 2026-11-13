import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';

DietaryPreferences _build({
  Map<Allergen, AllergySeverity> allergies = const {Allergen.peanuts: AllergySeverity.severe},
  String? allergyNote,
  DietStyle dietStyle = DietStyle.regular,
  Set<FoodPreference> preferences = const {FoodPreference.likesNuts},
}) =>
    DietaryPreferences(allergies: allergies, allergyNote: allergyNote, dietStyle: dietStyle, preferences: preferences);

void main() {
  test('bằng nhau theo nội dung, không theo thứ tự thêm vào', () {
    final first = _build(allergies: {Allergen.milk: AllergySeverity.mild, Allergen.fish: AllergySeverity.severe});
    final second = _build(allergies: {Allergen.fish: AllergySeverity.severe, Allergen.milk: AllergySeverity.mild});

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('khác mức dị ứng, ghi chú, chế độ ăn hoặc sở thích thì khác nhau', () {
    final base = _build();

    expect(_build(allergies: {Allergen.peanuts: AllergySeverity.mild}), isNot(base));
    expect(_build(allergyNote: 'Kiwi'), isNot(base));
    expect(_build(dietStyle: DietStyle.vegan), isNot(base));
    expect(_build(preferences: {}), isNot(base));
  });

  test('danh sách không sửa được từ bên ngoài', () {
    final allergies = {Allergen.eggs: AllergySeverity.severe};
    final dietary = _build(allergies: allergies);
    allergies[Allergen.fish] = AllergySeverity.mild;

    expect(dietary.allergies, {Allergen.eggs: AllergySeverity.severe});
    expect(() => dietary.preferences.add(FoodPreference.noOrganMeat), throwsUnsupportedError);
  });

  test('mỗi nhóm dị ứng có tag riêng của Open Food Facts', () {
    expect(Allergen.values.map((allergen) => allergen.openFoodFactsTag).toSet(), hasLength(14));
    expect(Allergen.treeNuts.openFoodFactsTag, 'en:nuts');
  });
}
