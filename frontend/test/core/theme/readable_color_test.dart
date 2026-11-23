import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/theme/readable_color.dart';

void main() {
  const white = Color(0xFFFFFFFF);

  test('màu biểu đồ quá nhạt (#10B981) được làm đậm tới 4,5:1, giữ cùng sắc màu', () {
    const accent = Color(0xFF10B981);
    expect(contrastRatio(accent, white), lessThan(4.5));

    final readable = readableOn(accent, white);

    expect(contrastRatio(readable, white), greaterThanOrEqualTo(4.5));
    expect(HSLColor.fromColor(readable).hue, closeTo(HSLColor.fromColor(accent).hue, 1));
  });

  test('màu đã đủ tương phản thì giữ nguyên', () {
    const protein = Color(0xFF006398);

    expect(readableOn(protein, white), protein);
  });

  test('trên nền tối thì làm sáng lên', () {
    const background = Color(0xFF101413);
    const color = Color(0xFF006C49);

    final readable = readableOn(color, background);

    expect(contrastRatio(readable, background), greaterThanOrEqualTo(4.5));
    expect(HSLColor.fromColor(readable).lightness, greaterThan(HSLColor.fromColor(color).lightness));
  });
}
