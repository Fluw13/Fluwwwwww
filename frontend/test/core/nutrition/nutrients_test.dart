import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';

void main() {
  test('chỉ số không có dữ liệu trả về null, không phải 0', () {
    final apple = Nutrients({Nutrient.energyKcal: 52});

    expect(apple[Nutrient.energyKcal], 52);
    expect(apple[Nutrient.sugarsG], isNull);
  });

  test('0 là dữ liệu thật (vd 0 g đường), khác với không có dữ liệu', () {
    final water = Nutrients({Nutrient.sugarsG: 0});

    expect(water[Nutrient.sugarsG], 0);
    expect(water[Nutrient.sugarsG], isNotNull);
  });

  test('nhân theo khối lượng: 250 g táo từ số liệu cho 100 g', () {
    final per100g = Nutrients({Nutrient.energyKcal: 52, Nutrient.proteinG: 0.3});

    final portion = per100g.scaled(2.5);

    expect(portion[Nutrient.energyKcal], closeTo(130, 1e-9));
    expect(portion[Nutrient.proteinG], closeTo(0.75, 1e-9));
    expect(portion[Nutrient.sugarsG], isNull);
  });

  test('từ chối số âm, NaN và vô cực', () {
    expect(() => Nutrients({Nutrient.proteinG: -1}), throwsArgumentError);
    expect(() => Nutrients({Nutrient.proteinG: double.nan}), throwsArgumentError);
    expect(() => Nutrients({Nutrient.proteinG: double.infinity}), throwsArgumentError);
  });

  test('không sửa được dữ liệu từ bên ngoài sau khi tạo', () {
    final source = {Nutrient.energyKcal: 100.0};
    final nutrients = Nutrients(source);

    source[Nutrient.energyKcal] = 999;

    expect(nutrients[Nutrient.energyKcal], 100);
    expect(() => nutrients.asMap()[Nutrient.energyKcal] = 1, throwsUnsupportedError);
  });

  test('bằng nhau khi cùng các chỉ số và giá trị, không phụ thuộc thứ tự', () {
    final first = Nutrients({Nutrient.energyKcal: 100, Nutrient.proteinG: 5});
    final second = Nutrients({Nutrient.proteinG: 5, Nutrient.energyKcal: 100});

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(Nutrients({Nutrient.energyKcal: 100})));
    expect(first, isNot(Nutrients({Nutrient.energyKcal: 100, Nutrient.proteinG: 6})));
  });
}
