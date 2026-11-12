import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/core/theme/app_typography.dart';
import 'package:fluw/core/theme/nutrient_colors.dart';

double _contrast(Color first, Color second) {
  final lighter = max(first.computeLuminance(), second.computeLuminance());
  final darker = min(first.computeLuminance(), second.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('giao diện sáng dùng đúng màu lấy từ thiết kế', () {
    final scheme = AppTheme.light().colorScheme;

    expect(scheme.primary, const Color(0xFF006C49));
    expect(scheme.surface, const Color(0xFFFAF8FF));
    expect(scheme.onSurface, const Color(0xFF131B2E));
    expect(scheme.error, const Color(0xFFBA1A1A));
  });

  for (final (name, theme) in [('sáng', AppTheme.light()), ('tối', AppTheme.dark())]) {
    group('giao diện $name đạt độ tương phản WCAG AA cho chữ (4,5:1)', () {
      final scheme = theme.colorScheme;
      final pairs = {
        'chữ trên nút chính': (scheme.onPrimary, scheme.primary),
        'chữ trên nền': (scheme.onSurface, scheme.surface),
        'chữ phụ trên nền': (scheme.onSurfaceVariant, scheme.surface),
        'chữ phụ trên thẻ': (scheme.onSurfaceVariant, scheme.surfaceContainerLowest),
        'chữ lỗi trên nền': (scheme.error, scheme.surface),
        'tab đang chọn trên thanh dưới': (scheme.primary, scheme.surfaceContainerLowest),
      };

      for (final MapEntry(key: label, value: (foreground, background)) in pairs.entries) {
        test(label, () {
          expect(_contrast(foreground, background), greaterThanOrEqualTo(4.5));
        });
      }
    });

    test('giao diện $name có bảng màu chỉ số dinh dưỡng', () {
      expect(theme.extension<NutrientColors>(), isNotNull);
    });
  }

  test('tiêu đề dùng Plus Jakarta Sans, nội dung dùng Inter', () {
    final textTheme = AppTheme.light().textTheme;

    expect(textTheme.titleLarge?.fontFamily, AppFonts.heading);
    expect(textTheme.headlineMedium?.fontFamily, AppFonts.heading);
    expect(textTheme.bodyMedium?.fontFamily, AppFonts.body);
    expect(textTheme.labelMedium?.fontFamily, AppFonts.body);
  });

  test('NutrientColors chuyển màu mượt giữa sáng và tối', () {
    final halfway = NutrientColors.light.lerp(NutrientColors.dark, 0.5);

    expect(halfway.protein, Color.lerp(NutrientColors.light.protein, NutrientColors.dark.protein, 0.5));
    expect(NutrientColors.light.lerp(null, 0.5), NutrientColors.light);
  });
}
