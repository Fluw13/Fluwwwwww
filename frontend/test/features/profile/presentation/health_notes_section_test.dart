import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/theme/app_theme.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/presentation/health_notes_section.dart';

import '../domain/profile_fixture.dart';

void main() {
  final theme = AppTheme.light();

  Future<List<String>> pump(WidgetTester tester, HealthProfile profile) async {
    final edits = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HealthNotesSection(profile: profile, onEdit: () => edits.add('edit')),
          ),
        ),
      ),
    );
    return edits;
  }

  testWidgets('dị ứng nặng lên đầu, nền màu lỗi; dị ứng nhẹ màu cảnh báo; bệnh nền giữ mô tả; đếm số mục', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      buildProfile(
        conditions: {HealthCondition.gout},
        conditionNote: 'Viêm xoang',
        dietary: DietaryPreferences(
          allergies: {Allergen.peanuts: AllergySeverity.mild, Allergen.crustaceans: AllergySeverity.severe},
          allergyNote: 'Phấn hoa',
          dietStyle: DietStyle.regular,
          preferences: const {},
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('Tôm, cua (giáp xác)')).dy,
      lessThan(tester.getTopLeft(find.text('Đậu phộng (lạc)')).dy),
    );
    Finder onBlock(String text, Color color) => find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == color,
      ),
    );
    expect(onBlock('Tôm, cua (giáp xác)', theme.colorScheme.errorContainer), findsOneWidget);
    expect(onBlock('Đậu phộng (lạc)', theme.colorScheme.tertiaryContainer), findsOneWidget);
    expect(find.text('Mức: Nặng'), findsOneWidget);
    expect(find.text('Mức: Nhẹ'), findsOneWidget);
    expect(find.text('Chỉ lưu làm ghi chú. Fluw chưa có dữ liệu để cảnh báo bệnh này.'), findsOneWidget);
    expect(find.text('Phấn hoa'), findsOneWidget);
    expect(find.text('Viêm xoang'), findsOneWidget);
    expect(find.bySemanticsLabel('3 mục'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('chưa khai báo gì thì nói rõ, không có số đếm; nút thêm mở form hồ sơ', (tester) async {
    final edits = await pump(tester, buildProfile());

    expect(find.text('Chưa khai báo dị ứng hay bệnh nền.'), findsOneWidget);
    expect(find.textContaining('Open Food Facts'), findsNothing);
    await tester.tap(find.text('Thêm dị ứng / bệnh nền'));
    expect(edits, ['edit']);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
