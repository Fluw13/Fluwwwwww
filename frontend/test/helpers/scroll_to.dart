import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls the vertical list the user can touch (offstage tabs and pages below keep their own lists) until [finder]
/// is on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder, {double delta = 200}) async {
  // Picked once: a list ignores pointers while it scrolls, so a hit-test finder would lose it mid-drag.
  final touchable = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical);
  final list = touchable.hitTestable().evaluate().first;
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byElementPredicate((element) => identical(element, list)),
    maxScrolls: 500,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
