import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/fluw_palette.dart';
import 'package:frontend/core/theme/score_colors.dart';
import 'package:frontend/models/score_level.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const double minTextContrast = 4.5;

  for (final (String name, FluwPalette palette) in [
    ('sáng', FluwPalette.light),
    ('tối', FluwPalette.dark),
  ]) {
    group('FluwPalette $name', () {
      test('chữ chính và chữ phụ đạt tương phản WCAG AA trên nền và thẻ', () {
        for (final Color ground in [palette.background, palette.surface, palette.surfaceMuted]) {
          expect(_contrast(palette.textPrimary, ground), greaterThanOrEqualTo(minTextContrast));
          expect(_contrast(palette.textSecondary, ground), greaterThanOrEqualTo(minTextContrast));
        }
      });

      test('chữ trên nút chính đạt tương phản WCAG AA', () {
        expect(
          _contrast(palette.onPrimaryAction, palette.primaryAction),
          greaterThanOrEqualTo(minTextContrast),
        );
      });

      test('chữ trên nhãn điểm đạt tương phản WCAG AA ở cả 3 mức', () {
        for (final ScoreLevel level in ScoreLevel.values) {
          final ScoreColors colors = palette.scoreColors(level);
          expect(_contrast(colors.text, colors.container), greaterThanOrEqualTo(minTextContrast), reason: level.name);
        }
      });

      test('vòng điểm đạt tương phản đồ họa 3:1 trên thẻ và trên rãnh vòng', () {
        for (final ScoreLevel level in ScoreLevel.values) {
          final Color ring = palette.scoreColors(level).ring;
          expect(_contrast(ring, palette.surface), greaterThanOrEqualTo(3.0), reason: level.name);
          expect(_contrast(ring, palette.surfaceMuted), greaterThanOrEqualTo(3.0), reason: level.name);
        }
      });

      test('chữ nhấn (accentText) đọc được trên thẻ', () {
        expect(_contrast(palette.accentText, palette.surface), greaterThanOrEqualTo(minTextContrast));
      });
    });
  }

  test('scoreColors trả đúng bộ màu theo mức điểm', () {
    const FluwPalette palette = FluwPalette.light;
    expect(palette.scoreColors(ScoreLevel.good), same(palette.scoreGood));
    expect(palette.scoreColors(ScoreLevel.moderate), same(palette.scoreModerate));
    expect(palette.scoreColors(ScoreLevel.poor), same(palette.scorePoor));
  });

  test('lerp trả về đúng hai đầu khi chuyển sáng ↔ tối', () {
    final FluwPalette start = FluwPalette.light.lerp(FluwPalette.dark, 0);
    final FluwPalette end = FluwPalette.light.lerp(FluwPalette.dark, 1);

    expect(start.background, FluwPalette.light.background);
    expect(end.background, FluwPalette.dark.background);
    expect(end.scorePoor.text, FluwPalette.dark.scorePoor.text);
    expect(end.ringGlowOpacity, FluwPalette.dark.ringGlowOpacity);
  });

  testWidgets('context.palette dùng bảng màu theo độ sáng khi theme không có extension', (tester) async {
    late FluwPalette resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            resolved = context.palette;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved, same(FluwPalette.dark));
  });
}
