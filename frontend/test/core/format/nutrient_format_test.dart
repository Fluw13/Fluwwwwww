import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/format/nutrient_format.dart';

void main() {
  test('gam: 1 chữ số thập phân, dấu phẩy, bỏ ",0"', () {
    expect(NutrientFormat.grams(9.8), '9,8');
    expect(NutrientFormat.grams(3), '3');
    expect(NutrientFormat.grams(12.44), '12,4');
    expect(NutrientFormat.grams(0), '0');
  });

  test('kcal làm tròn số nguyên', () {
    expect(NutrientFormat.kcal(411.6), '412');
    expect(NutrientFormat.kcal(0), '0');
  });

  test('hàng nghìn dùng dấu chấm', () {
    expect(NutrientFormat.kcal(2000), '2.000');
    expect(NutrientFormat.kcal(1234567), '1.234.567');
    expect(NutrientFormat.grams(1250.25), '1.250,3');
    expect(NutrientFormat.kcal(999), '999');
  });

  test('giá trị âm (dữ liệu lỗi) hiển thị là 0, không ra "-0"', () {
    expect(NutrientFormat.grams(-0.04), '0');
    expect(NutrientFormat.kcal(-5), '0');
  });

  test('thiếu dữ liệu hiển thị "—", không đổi thành 0', () {
    expect(NutrientFormat.grams(null), NutrientFormat.missing);
    expect(NutrientFormat.kcal(null), NutrientFormat.missing);
  });
}
