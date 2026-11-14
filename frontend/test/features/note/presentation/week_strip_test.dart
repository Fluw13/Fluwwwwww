import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/presentation/week_strip.dart';

void main() {
  Future<void> pumpStrip(WidgetTester tester, CalendarDate selected) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 358,
              child: WeekStrip(
                selected: selected,
                today: CalendarDate(2026, 11, 11),
                daysWithEntries: const {},
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect visibleRow(WidgetTester tester) => tester.getRect(find.byType(SingleChildScrollView));

  testWidgets('màn hẹp: chọn Chủ nhật thì dải ngày tự cuộn để thấy trọn ngày đó', (tester) async {
    await pumpStrip(tester, CalendarDate(2026, 11, 15));

    final sunday = tester.getRect(find.text('15'));
    expect(visibleRow(tester).left <= sunday.left && sunday.right <= visibleRow(tester).right, isTrue);
  });

  testWidgets('đổi sang thứ Hai thì cuộn ngược lại, thấy thứ Hai', (tester) async {
    await pumpStrip(tester, CalendarDate(2026, 11, 15));
    await pumpStrip(tester, CalendarDate(2026, 11, 9));

    final monday = tester.getRect(find.text('9'));
    expect(visibleRow(tester).left <= monday.left && monday.right <= visibleRow(tester).right, isTrue);
  });
}
