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
        'chữ trên primaryContainer (avatar)': (scheme.onPrimaryContainer, scheme.primaryContainer),
        'chữ trên secondaryContainer': (scheme.onSecondaryContainer, scheme.secondaryContainer),
        'chữ trên tertiaryContainer': (scheme.onTertiaryContainer, scheme.tertiaryContainer),
        'chữ trên errorContainer': (scheme.onErrorContainer, scheme.errorContainer),
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

  test('các lớp nền của giao diện sáng đậm dần đúng thứ tự, cùng một tông', () {
    final scheme = AppTheme.light().colorScheme;
    final layers = [
      scheme.surfaceContainerLowest,
      scheme.surfaceContainerLow,
      scheme.surfaceContainer,
      scheme.surfaceContainerHigh,
      scheme.surfaceContainerHighest,
    ];

    for (var index = 1; index < layers.length; index++) {
      expect(layers[index].computeLuminance(), lessThan(layers[index - 1].computeLuminance()));
    }
    for (final layer in layers.skip(1)) {
      expect(layer.b, greaterThan(layer.g), reason: 'các lớp nền trong thiết kế ngả tím xanh, không ngả xanh lá');
    }
  });

  test('tiêu đề dùng Plus Jakarta Sans, nội dung dùng Inter', () {
    final textTheme = AppTheme.light().textTheme;

    expect(textTheme.titleLarge?.fontFamily, AppFonts.heading);
    expect(textTheme.headlineMedium?.fontFamily, AppFonts.heading);
    expect(textTheme.bodyMedium?.fontFamily, AppFonts.body);
    expect(textTheme.labelMedium?.fontFamily, AppFonts.body);
  });

  test('tiêu đề và header Plus Jakarta Sans 600, số lớn Plus Jakarta Sans 700 như file Figma', () {
    final textTheme = AppTheme.light().textTheme;

    for (final style in [textTheme.displayLarge, textTheme.titleLarge]) {
      expect(style?.fontFamily, AppFonts.heading);
      expect(style?.fontWeight, FontWeight.w600);
    }
    expect(textTheme.titleLarge?.fontSize, 18);
    for (final style in [textTheme.headlineMedium, textTheme.numberMedium]) {
      expect(style?.fontFamily, AppFonts.heading);
      expect(style?.fontWeight, FontWeight.w700);
    }
    expect(textTheme.headlineMedium?.fontSize, 28);
  });

  test('chữ nội dung theo thang chữ của thiết kế, chữ phụ màu onSurfaceVariant ở cả sáng và tối', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final textTheme = theme.textTheme;

      expect((textTheme.bodyMedium?.fontSize, textTheme.bodyMedium?.fontWeight), (13, FontWeight.w500));
      expect((textTheme.labelSmall?.fontSize, textTheme.labelSmall?.fontWeight), (11, FontWeight.w700));
      expect((textTheme.titleSmall?.fontSize, textTheme.titleSmall?.fontWeight), (14, FontWeight.w600));
      expect(textTheme.bodySmall?.color, theme.colorScheme.onSurfaceVariant);
    }
  });

  test('NutrientColors chuyển màu mượt giữa sáng và tối', () {
    final halfway = NutrientColors.light.lerp(NutrientColors.dark, 0.5);

    expect(halfway.protein, Color.lerp(NutrientColors.light.protein, NutrientColors.dark.protein, 0.5));
    expect(NutrientColors.light.lerp(null, 0.5), NutrientColors.light);
  });
}
